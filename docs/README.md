&nbsp;

## Adding the resurface.io Helm chart repo

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add resurfaceio https://resurfaceio.github.io/containers

And run

    helm repo update

to retrieve the latest versions of the packages.

You can then run `helm search repo resurfaceio` to see the charts.

## Installing Resurface in your k8s cluster

To install the resurface chart:

    helm install resurface resurfaceio/resurface -n resurface --create-namespace --set entitlementToken=<<paste your entitlement token here!>>

To uninstall the chart:

    helm delete resurface -n resurface

