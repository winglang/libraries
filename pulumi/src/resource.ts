import { Construct } from "@winglang/sdk/lib/core/types";
import { ResourceDefinition, VariableDefinition } from "./schema";

export interface PulumiResourceProps extends ResourceDefinition {

}

export class PulumiResource extends Construct {
  public readonly props: PulumiResourceProps;

  constructor(scope: Construct, id: string, props: PulumiResourceProps) {
    super(scope, id);

    this.props = props;
  }

  public get definition(): ResourceDefinition {
    return this.props;
  }

  public get self(): string {
    return `\${${this.name}}`;
  }

  public get name(): string {
    return renderName(this);
  }

  public get ref() {
    return this.attr("id");
  }

  public attr(name: string) {
    return `\${${this.name}.${name}}`;
  }
}

export class PulumiVariable extends Construct {
  constructor(scope: Construct, id: string, public readonly props: VariableDefinition) {
    super(scope, id);
  }

  public attr(name: string) {
    return `\${${this.name}.${name}}`;
  }

  public get name(): string {
    return this.node.addr;
  }
}

function renderName(c: Construct): string {
  const components = [
    c.node.id,
    c.node.addr.substring(0, 6),
  ];

  return components.map(c => c.replace(/^[a-zA-Z0-9]+:/g, "").replace(/:/g, "-").toLocaleLowerCase()).join("-");
}
