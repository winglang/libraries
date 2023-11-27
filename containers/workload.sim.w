bring http;
bring util;
bring cloud;
bring sim;
bring "./api.w" as api;
bring "./utils.w" as utils;

pub class Workload_sim {
  publicUrlKey: str?;
  internalUrlKey: str?;
  containerIdKey: str;

  pub publicUrl: str?;
  pub internalUrl: str?;

  props: api.WorkloadProps;
  appDir: str;
  imageTag: str;
  public: bool;
  state: sim.State;
  
  new(props: api.WorkloadProps) {
    this.appDir = utils.entrypointDir(this);
    this.props = props;
    this.state = new sim.State();
    this.containerIdKey = "container_id";

    let hash = utils.resolveContentHash(this, props);
    if hash? {
      this.imageTag = "{props.name}:{hash}";
    } else {
      this.imageTag = props.image;
    }

    this.public = props.public ?? false;

    if this.public {
      if !props.port? {
        throw "'port' is required if 'public' is enabled";
      }

      let key = "public_url";
      this.publicUrl = this.state.token(key);
      this.publicUrlKey = key;
    }

    if props.port? {
      let key = "internal_url";
      this.internalUrl = this.state.token(key);
      this.internalUrlKey = key;
    }

    let s = new cloud.Service(inflight () => {
      this.start();
      return () => { this.stop(); };
    });

    std.Node.of(s).hidden = true;
    std.Node.of(this.state).hidden = true;
  }

  inflight start(): void {
    log("starting workload...");

    let opts = this.props;

    // if this a reference to a local directory, build the image from a docker file
    if utils.isPathInflight(opts.image) {
      // check if the image is already built
      try {
        utils.shell("docker", ["inspect", this.imageTag]);
        log("image {this.imageTag} already exists");
      } catch {
        log("building locally from {opts.image} and tagging {this.imageTag}...");
        utils.shell("docker", ["build", "-t", this.imageTag, opts.image], this.appDir);
      }
    } else {
      try {
        utils.shell("docker", ["inspect", this.imageTag]);
        log("image {this.imageTag} already exists");
      } catch {
        log("pulling {this.imageTag}");
        utils.shell("docker", ["pull", this.imageTag]);
      }
    }

    // start the new container
    let dockerRun = MutArray<str>[];
    dockerRun.push("run");
    dockerRun.push("--detach");

    if let port = opts.port {
      dockerRun.push("-p");
      dockerRun.push("{port}");
    }

    if let env = opts.env {
      if env.size() > 0 {
        dockerRun.push("-e");
        for k in env.keys() {
          dockerRun.push("{k}={env.get(k)}");
        }
      }
    }

    dockerRun.push(this.imageTag);

    if let runArgs = this.props.args {
      for a in runArgs {
        dockerRun.push(a);
      }
    }

    log("starting container from image {this.imageTag}");
    log("docker {dockerRun.join(" ")}");
    let containerId = utils.shell("docker", dockerRun.copy()).trim();
    this.state.set(this.containerIdKey, containerId);

    log("containerId={containerId}");

    let out = Json.parse(utils.shell("docker", ["inspect", containerId]));

    if let port = opts.port {
      let hostPort = out.tryGetAt(0)?.tryGet("NetworkSettings")?.tryGet("Ports")?.tryGet("{port}/tcp")?.tryGetAt(0)?.tryGet("HostPort")?.tryAsStr();
      if !hostPort? {
        throw "Container does not listen to port {port}";
      }

      let publicUrl = "http://localhost:{hostPort}";

      if let k = this.publicUrlKey {
        this.state.set(k, publicUrl);
      }

      if let k = this.internalUrlKey {
        this.state.set(k, "http://host.docker.internal:{hostPort}");
      }

      if let readiness = opts.readiness {
        let readinessUrl = "{publicUrl}{readiness}";
        log("waiting for container to be ready: {readinessUrl}...");
        util.waitUntil(inflight () => {
          try {
            return http.get(readinessUrl).ok;
          } catch {
            return false;
          }
        }, interval: 0.1s);
      }
    }
  }

  inflight stop() {
    let containerId = this.state.get(this.containerIdKey).asStr();
    log("stopping container {containerId}");
    utils.shell("docker", ["rm", "-f", containerId]);
  }
}