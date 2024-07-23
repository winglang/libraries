bring cloud;
bring util;
bring tf;

pub struct CacheProps {
  /// A secret containing the Momento API key to use for accessing
  /// the cache at runtime.
  token: cloud.Secret;

  /// The name of the cache.
  /// @default - a unique id will be generated
  name: str?;

  /// The default time-to-live for cache entries.
  /// @default 60
  defaultTtl: duration?;
}

pub interface ICache {
  /// Get a value from the cache.
  inflight get(key: str, opts: CacheGetOptions?): str?;

  /// Set a value in the cache.
  inflight set(key: str, value: str, opts: CacheSetOptions?): void;
}

pub struct CacheGetOptions {}

pub struct CacheSetOptions {
  /// The time-to-live for the cache entry, in seconds.
  /// @default 60s
  ttl: duration?;
}

pub class Cache {
  inner: ICache;
  new(props: CacheProps) {
    let target = util.env("WING_TARGET");
    let node = nodeof(this);
    let name = props.name ?? node.id.substring(0, 8) + "_" + node.addr.substring(34);
    let token = props.token;
    let defaultTtl = props.defaultTtl ?? 60s;
    if target.startsWith("tf") {
      this.inner = new Cache_tf({ token, name, defaultTtl });
    } else {
      throw "unsupported target: " + target;
    }
  }

  pub inflight get(key: str): str? {
    return this.inner.get(key);
  }

  pub inflight set(key: str, value: str, opts: CacheSetOptions?): void {
    this.inner.set(key, value, opts);
  }
}

class Cache_tf impl ICache {
  name: str;
  token: cloud.Secret;

  new(props: CacheProps) {
    this.name = props.name!;
    this.token = props.token;

    // Create a momento_cache resource to model the cache.
    new tf.Resource(type: "momento_cache", attributes: {
      name: this.name,
    });

    // Ensure a provider is available.
    MomentoProvider.getOrCreate(this);
  }

  extern "./cache.ts" static inflight _get(token: str, cacheName: str, key: str): str?;
  extern "./cache.ts" static inflight _set(token: str, cacheName: str, key: str, value: str, ttl: num): void;

  pub inflight get(key: str): str? {
    let token = this.token.value(cache: true);
    return Cache_tf._get(token, this.name, key);
  }

  pub inflight set(key: str, value: str, opts: CacheSetOptions?): void {
    let token = this.token.value(cache: true);
    let ttl = opts?.ttl ?? 60s;
    Cache_tf._set(token, this.name, key, value, ttl.seconds);
  }
}

class MomentoProvider {
  pub static getOrCreate(scope: std.IResource): tf.Provider {
    let root = nodeof(scope).root;
    let singletonKey = "MomentoProvider";
    let existing = nodeof(root).tryFindChild(singletonKey);
    if existing != nil {
      return unsafeCast(existing);
    }

    return new tf.Provider(
      name: "momento",
      source: "momentohq/momento",
      version: "0.1.0",
    ) as singletonKey in root;
  }
}
