import { core, std } from "@winglang/sdk";
import { PulumiYaml, ResourceDefinition, VariableDefinition } from "./schema";
import * as fs from "fs";
import * as path from "path";
import { PulumiResource, PulumiVariable } from "./resource";

export class PulumiApp extends core.App {
  _target = "pulumi" as any;
  outdir: string;

  constructor(props: core.AppProps) {
    super(undefined as any, "Default", props);

    if (!props.outdir) {
      throw new Error("outdir is required");
    }

    this.outdir = props.outdir;

    std.Node._markRoot(props.rootConstruct);
    new props.rootConstruct(this, props.rootId ?? "Default");
  }

  public synth(): string {


    // call preSynthesize() on every construct in the tree
    core.preSynthesizeAllConstructs(this);

    if (this._synthHooks?.preSynthesize) {
      this._synthHooks.preSynthesize.forEach((hook) => hook(this));
    }

    const resources: Record<string, ResourceDefinition> = {};
    const variables: Record<string, VariableDefinition> = {};
    const yaml: PulumiYaml = {
      name: "wing",
      runtime: "yaml",
      resources,
      variables,
    };

    for (const n of this.node.findAll()) {
      if (n instanceof PulumiResource) {
        resources[n.name] = n.definition;
      }
    }

    for (const n of this.node.findAll()) {
      if (n instanceof PulumiVariable) {
        variables[n.name] = n.props;
      }
    }

    const outfile = path.join(this.outdir, "Pulumi.yaml");
    fs.writeFileSync(outfile, JSON.stringify(yaml, null, 2));

    // write `outdir/tree.json`
    core.synthesizeTree(this, this.outdir);

    // write `outdir/connections.json`
    core.Connections.of(this).synth(this.outdir);

    console.log(outfile);
    return outfile;
  }
}