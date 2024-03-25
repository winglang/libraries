pub struct CognitoProps {
  name: str?;
  usernameAttributes: Array<str>?;
  autoVerifiedAttributes: Array<str>?;
  schema: Json?;
  headerKey: str?;
}

pub interface ICognito {
  get(path: str): void;
  post(path: str): void;
  put(path: str): void;
  patch(path: str): void;
  delete(path: str): void;
  head(path: str): void;
  options(path: str): void;
  connect(path: str): void;

  inflight signUp(email: str, password: str): void;
  inflight adminConfirmUser(email: str): void;
  inflight initiateAuth(email: str, password: str): str;
}