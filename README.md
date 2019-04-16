# drone-helm

Simplified Drone plugin for Kubernetes/Helm

## What It Does

This is a Docker image that allows you to run [helm](https://helm.sh/). It
also contains [kubectl](https://kubernetes.io/docs/reference/kubectl/). These
require some configuration via environment variables, but when properly set
up, this image will let you run arbitray `kubectl` and `helm` commands
against your cluster.

This image is mostly useful as a [drone.io](https://drone.io/) build plugin.
The basic configuration is taken directly from
[ipedrazas/drone-helm](https://github.com/ipedrazas/drone-helm) to allow for
easy replacement of that plugin.

This image also contains the following plugins:

* [helm-diff](https://github.com/databus23/helm-diff)
* [helm-secrets](https://github.com/futuresimple/helm-secrets)

## Motivation

Drone points to `ipedrazas/drone-helm` from its plugin documentation, but it
is (apparently) not maintained by the Drone team. The project seems to be
maintained adequately and sees a lot of use. However, it seems to have some
inherent weaknesses:

* It is implemented in Go, which seems to be a singularly bad choice for this
  type of project
* Most features amount to adding flags to various `helm` commands
* The documentation severely lags behind feature implementation

The project mostly boils down to an attempt to reproduce `helm`'s CLI
interface in YAML. This is a losing battle, and after spending a few hours
creating a few trivial but useful pull requests for new features, decided
that the approach was fundamentally wrong.

This project aims to be as simple as possible while still adding value and
being useful. Instead of reinventing `helm`'s interface, you are allowed to
simply write `helm` commands that will be executed.

## Configuration

The images is configured with the same three environment variables as
`ipedrazas/drone-helm`:

* `API_SERVER`: Required.  The URI of the API server.
* `KUBERNETES_TOKEN`: Required. A bearer token for communicating with the
  cluster.
* `KUBERNETES_CERTIFICATE`: The base-64 encoded client certificate for
  communicating with the cluster. If this is not set then
  `--insecure-skip-tls-verify` will be set to `true`.

> **NOTE**:  These should generally be set using drone secrets.

The entrypoint script will configure kubectl, which will allow `helm` to work.

## Use

Most of the features and configuration in `ipedrazas/drone-helm` seemed to be
around two distinct areas: initialization and everything else, with the bulk
of everything else being related to the `upgrade` command. Therefore, the
user is responsible for first initializing helm.

Commands are specified via the `helm_commands` key in the pipeline step. This
should be a list of `helm` (or `kubectl` or anything else installed on the
image) commands provided as an array. A failure in any command should stop
the step and fail the build. Complex multi-line commands are supported:

```yaml
pipeline:
  helm:
    image: fanconnecttv/drone-helm
    helm_commands:
    - helm init --upgrade --wait
    - |
      helm secrets diff upgrade my-chart-staging ./charts/my-chart \
        --values charts/my-chart/values-staging.yaml \
        --values charts/my-chart/secrets.staging.yaml
    - |
      if [ "${DRONE_COMMIT_BRANCH}" == "master" ]
      then
        echo "We're on master!"
      else
        echo "Some lame branch"
      fi
    secrets:
    - api_server
    - kubernetes_token
    - aws_access_key_id
    - aws_secret_access_key
```

In the above example, it's assumed that AWS KMS is used to encrypt secrets
stored in the repo, so `helm-secrets` uses the extra secrets as environment
variables to configure AWS credentials. Similar but different approaches may
need to be used for other encryption methods like PGP. Refer to the
`helm-secrets` docs for more info.

## Caveats

This is the simplest thing that could work, so there are probably some rough
edges.

* The `helm_commands` are passed to the entrypoint via environment variable,
  which is a comma-separated list of commands. An embedded comma would almost
  certainly break the commands. Manual quoting in the YAML may be one approach
  to deal with this.
* This has so far only been run against drone 0.8. I'm not sure how the plugin
  interface has changed between 0.8 and 1.0. We definitely need examples of
  1.0-style configuration of this plugin and verification that this plugin
  works under 1.0.
