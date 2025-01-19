# Winglibs

Welcome! You've arrived to the warm and cozy home of the *Wing Trusted Library Ecosystem*.

This repository hosts the code for [Wing](https://winglang.io) libraries (also called "winglibs")
that we consider trusted and that meet our community's quality bar.

One of the cool things about trusted libraries is that we take care of building, testing and
publishing them for you.

<!-- WINGLIBS_TOC_START -->

| Library | npm package | Platforms |
| --- | --- | --- |
| [bedrock](./bedrock) | [@winglibs/bedrock](https://www.npmjs.com/package/@winglibs/bedrock) | sim, tf-aws |
| [budget](./budget) | [@winglibs/budget](https://www.npmjs.com/package/@winglibs/budget) | sim, tf-aws |
| [checks](./checks) | [@winglibs/checks](https://www.npmjs.com/package/@winglibs/checks) | * |
| [cloudv2](./cloudv2) | [@winglibs/cloudv2](https://www.npmjs.com/package/@winglibs/cloudv2) | sim, tf-aws |
| [cognito](./cognito) | [@winglibs/cognito](https://www.npmjs.com/package/@winglibs/cognito) | sim, tf-aws |
| [containers](./containers) | [@winglibs/containers](https://www.npmjs.com/package/@winglibs/containers) | sim, tf-aws |
| [dynamodb](./dynamodb) | [@winglibs/dynamodb](https://www.npmjs.com/package/@winglibs/dynamodb) | sim, tf-aws |
| [email](./email) | [@winglibs/email](https://www.npmjs.com/package/@winglibs/email) | sim, tf-aws |
| [eventbridge](./eventbridge) | [@winglibs/eventbridge](https://www.npmjs.com/package/@winglibs/eventbridge) | awscdk, sim, tf-aws |
| [fifoqueue](./fifoqueue) | [@winglibs/fifoqueue](https://www.npmjs.com/package/@winglibs/fifoqueue) | sim, tf-aws |
| [github](./github) | [@winglibs/github](https://www.npmjs.com/package/@winglibs/github) | * |
| [jwt](./jwt) | [@winglibs/jwt](https://www.npmjs.com/package/@winglibs/jwt) | * |
| [k8s](./k8s) | [@winglibs/k8s](https://www.npmjs.com/package/@winglibs/k8s) | k8s |
| [lock](./lock) | [@winglibs/lock](https://www.npmjs.com/package/@winglibs/lock) | * |
| [messagefanout](./messagefanout) | [@winglibs/messagefanout](https://www.npmjs.com/package/@winglibs/messagefanout) | sim, tf-aws |
| [momento](./momento) | [@winglibs/momento](https://www.npmjs.com/package/@winglibs/momento) | sim, tf-aws, tf-azure, tf-gcp |
| [ngrok](./ngrok) | [@winglibs/ngrok](https://www.npmjs.com/package/@winglibs/ngrok) | * |
| [openai](./openai) | [@winglibs/openai](https://www.npmjs.com/package/@winglibs/openai) | * |
| [postgres](./postgres) | [@winglibs/postgres](https://www.npmjs.com/package/@winglibs/postgres) | sim, tf-aws |
| [pulumi](./pulumi) | [@winglibs/pulumi](https://www.npmjs.com/package/@winglibs/pulumi) | sim |
| [python](./python) | [@winglibs/python](https://www.npmjs.com/package/@winglibs/python) | sim, tf-aws |
| [react](./react) | [@winglibs/react](https://www.npmjs.com/package/@winglibs/react) | sim, tf-aws |
| [redis](./redis) | [@winglibs/redis](https://www.npmjs.com/package/@winglibs/redis) | sim |
| [sagemaker](./sagemaker) | [@winglibs/sagemaker](https://www.npmjs.com/package/@winglibs/sagemaker) | sim, tf-aws |
| [ses](./ses) | [@winglibs/ses](https://www.npmjs.com/package/@winglibs/ses) | sim, tf-aws |
| [simtools](./simtools) | [@winglibs/simtools](https://www.npmjs.com/package/@winglibs/simtools) | sim |
| [slack](./slack) | [@winglibs/slack](https://www.npmjs.com/package/@winglibs/slack) | sim, tf-aws |
| [sns](./sns) | [@winglibs/sns](https://www.npmjs.com/package/@winglibs/sns) | awscdk, sim, tf-aws |
| [tf](./tf) | [@winglibs/tf](https://www.npmjs.com/package/@winglibs/tf) | sim, tf-aws |
| [tsoa](./tsoa) | [@winglibs/tsoa](https://www.npmjs.com/package/@winglibs/tsoa) | sim |
| [vite](./vite) | [@winglibs/vite](https://www.npmjs.com/package/@winglibs/vite) | sim, tf-aws |
| [websockets](./websockets) | [@winglibs/websockets](https://www.npmjs.com/package/@winglibs/websockets) | awscdk, sim, tf-aws |

_Generated with `mkrepo.sh`. To update the list of supported platforms for a winglib, please update the "wing" section in its package.json file._

<!-- WINGLIBS_TOC_END -->

## How is this repository structured?

The code for each library is located in a subdirectory named after the library. For example, the
`websockets` library is located under [`./websockets`](./websockets/).

Wing libraries are published to npm under the `@winglibs` scope, and there's a `package.json` file
in the library's directory.

A set of GitHub Workflows are maintained for each library under the [.github](./github/) directory.
These workflows, as well as other artifacts in this repository (such as the table of contents in
this README) are are generated using a tool called `mkrepo`, which can be executed using the
`./mkrepo.sh` script at the root of this repository. The source code for this tool is can be found
under [.mkrepo](./.mkrepo/) (and it is written in Wing of course).

## How do I add a new library?

It's so damn easy.

Clone this repository:

```sh
git clone https://github.com/winglang/winglibs.git
```

Change to the `winglibs` directory:

```sh
cd winglibs
```

Use the fabulous `mklib.sh` script to scaffold your library:

```sh
./mklib.sh my-awesome-lib
```

This will create a subdirectory called `my-awesome-lib` with some initial source code and a test. It
will also create a github workflow which will take care of building, testing and publishing your
library to npm.

Now do your magic.

When you are ready, submit a pull request to this repository. Someone from the team will review it
and will hopefully provide you with useful feedback and a lot of love, and eventually merge it into
`main`, and your library will be live.

## Updating libraries

If you wish to publish an update to your library, simply submit a new pull request with your update.
Once the PR is merged, your new version will be published.

- :v: Make sure you use a conventional commit title. (`feat:` for new features, `fix:` for bug fix
  and `chore:` for anything else).
- :v: **DON'T FORGET!** You will need to manually bump the `version` field of your library based on
the semantic version update. In the future we plan to automate this so that bumps will happen
automatically.

  > ### A quick primer on semantic versioning
  > 
  > Semantic versioning is a convention for version numbers that is commonly used to indicate the type
  > of update. The version number consists of three components: `MAJOR`.`MINOR`.`PATCH`:
  >
  > * The `MAJOR` component must be bumped if the update includes a **breaking change**.
  > * The `MINOR` component must be bumped if the update includes a **new feature**.
  > * The `PATCH` component must be bumped if the update includes a **bug fix**.
  >
  > Before 1.0.0, the `MAJOR` component is always `0`, the `MINOR` component represents breaking
  > changes and the `PATCH` component represents new features *and* bug fixes.

## Consuming trusted libraries

To consume these libraries, users just need to:

```sh
npm i @winglibs/my-awesome-lib
```

And then:

```js
bring my-awesome-lib
```

## Writing Wing Libraries

See [docs](https://www.winglang.io/docs/libraries#creating-a-wing-library).

Please note that it refers to writing libraries that are not published here, so it includes instructions for things that you get here automatically when using the `mklib.sh` script to scaffold your library.

To specify the platforms your library supports, you can add a `wing.platforms` field to your `package.json`:

```json
{
  "name": "@winglibs/my-awesome-lib",
  "version": "0.0.1",
  "wing": {
    "platforms": [
      "sim",
      "tf-aws"
    ]
  }
}
```

## License

This repository is licensed under the [MIT License](./LICENSE), unless otherwise specified in a
library directory.
