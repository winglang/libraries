bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;

pub class Aws {
  pub static getOrCreate(scope: std.IResource): Aws {
    let stack = nodeof(scope).root;
    let id = "WingAwsUtil";
    let existing: Aws? = unsafeCast(nodeof(stack).tryFindChild(id));
    return (existing ?? new Aws() as id in stack);
  }

  regionData: aws.dataAwsRegion.DataAwsRegion;
  accountData: aws.dataAwsCallerIdentity.DataAwsCallerIdentity;


  new() { 
    this.regionData = new aws.dataAwsRegion.DataAwsRegion();
    this.accountData = new aws.dataAwsCallerIdentity.DataAwsCallerIdentity();
  }

  pub region(): str {
    return this.regionData.name;
  }

  pub accountId(): str {
    return this.accountData.accountId;
  }
}
