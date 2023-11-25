bring aws;
bring cloud;
bring util;
bring "constructs" as constructs;
bring "cdktf" as cdktf;
bring "@rybickic/cdktf-provider-neon" as rawNeon;
bring "@cdktf/provider-aws" as tfaws;

struct Credentials {
  host: str;
  user: str;
  password: str;
  dbname: str;
}

pub struct DatabaseProps {
  /**
   * The database name.
   */
  name: str;
  /**
   * The postgres version.
   * @default 15
   */
  pgVersion: num;
}

pub interface IDatabase {
  inflight query(query: str): Array<Map<Json>>;
}

pub class Database {
  inner: IDatabase;
  new(props: DatabaseProps) {
    let target = util.env("WING_TARGET");
    if target == "tf-aws" {
      this.inner = new DatabaseNeon(props);
    } else {
      throw "Unsupported target: " + target;
    }
  }

  pub inflight query(query: str): Array<Map<Json>> {
    return this.inner.query(query);
  }
}

pub class DatabaseNeon impl IDatabase {
  creds: cloud.Secret;

  new(props: DatabaseProps) {
    this.neonProvider();

    // TODO: share a project between multiple databases
    let project = new rawNeon.project.Project(
      name: props.name,
      pgVersion: props.pgVersion,
    );

    let db = new rawNeon.database.Database(
      projectId: project.id,
      branchId: project.defaultBranchId,
      ownerName: project.databaseUser,
      name: props.name,
    );

    this.creds = new cloud.Secret() as "NeonCredentials";

    // TODO: avoid hard-coding for AWS
    let secretsManagerSecret: tfaws.secretsmanagerSecret.SecretsmanagerSecret = unsafeCast(this.creds.node.findChild("Default"));
    let secretVersion = new tfaws.secretsmanagerSecretVersion.SecretsmanagerSecretVersion(
      secretId: secretsManagerSecret.id,
      secretString: cdktf.Fn.jsonencode({
        host: project.databaseHost,
        user: project.databaseUser,
        password: project.databasePassword,
        dbname: project.databaseName,
      })
    ) as "NeonCredentialsVersion";
  }

  neonProvider(): cdktf.TerraformProvider {
    let stack = cdktf.TerraformStack.of(this);
    let singletonKey = "WingNeonProvider";
    let existing = stack.node.tryFindChild(singletonKey);
    if existing? {
      return unsafeCast(existing);
    }

    return new rawNeon.provider.NeonProvider() as singletonKey in stack;
  }

  extern "./pg.js" static inflight _query(query: str, creds: Credentials): Array<Map<Json>>;

  pub inflight query(query: str): Array<Map<Json>> {
    let creds = Credentials.fromJson(this.creds.valueJson());
    return DatabaseNeon._query(query, creds);
  }
}
