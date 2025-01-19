export interface PulumiYaml {
  name: string;
  runtime: string;
  description?: string;
  config?: Record<string, string>;
  resources: Record<string, ResourceDefinition>;
  outputs?: Record<string, any>; // Outputs from the stack
  variables?: Record<string, VariableDefinition>; // Variables for the stack
}

export interface ResourceDefinition {
  type: string; // Resource type, e.g., "aws:s3/bucket:Bucket"
  properties?: ResourceProperties; // Properties specific to the resource type
  options?: ResourceOptions; // Options for resource behavior
}

export interface ResourceProperties {
  [key: string]: any; // Dynamic properties based on resource type
}

export interface ResourceOptions {
  dependsOn?: string[]; // Dependencies on other resources
  protect?: boolean; // Protection flag
  provider?: string; // Provider name
  deleteBeforeReplace?: boolean; // Replace strategy
  ignoreChanges?: string[]; // List of properties to ignore changes for
  parent?: string; // Parent resource
  additionalSecretOutputs?: string[]; // Outputs marked as secrets
  aliases?: string[]; // Aliases for resource renaming
  customTimeouts?: CustomTimeouts; // Timeouts for create, update, delete
}

export interface CustomTimeouts {
  create?: string; // Timeout for create operation
  update?: string; // Timeout for update operation
  delete?: string; // Timeout for delete operation
}

export interface VariableDefinition {
  [key: string]: any;
}
