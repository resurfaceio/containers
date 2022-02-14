# resurfaceio-helm-resurface

## Contents

- [resurfaceio-helm-resurface](#resurfaceio-helm-resurface)
  - [Contents](#contents)
  - [Requirements](#requirements)
  - [Description](#description)
  - [Values](#values)
  - [Single-node volatile storage configuration](#single-node-volatile-storage-configuration)
  - [Single-node persistent storage configuration](#single-node-persistent-storage-configuration)
  - [Multi-node volatile storage configuration](#multi-node-volatile-storage-configuration)
  - [Multi-node persistent storage configuration](#multi-node-persistent-storage-configuration)

## Requirements

- [Resurface entitlement token](https://resurface.io/installation)

## Description

Resurface can help with failure triage and root cause analysis, threat and
risk identification, and simply just knowing how your APIs are being used.
It identifies what's important in your API data, and can send warnings and
alerts in real-time for fast action.

With these charts, several resources are deployed in your cluster:

- Secret: Entitlement Token. It is used to pull images from the Resurface.io private container registry.
- Deployment: Resurface pod. Your very own Resurface instance.
- Service: API Explorer. It exposes the frontend for your Resurface instance.
- Service: Fluke server. It exposes the microservice used to import API calls into your Resurface instance.
- Daemonset: Packet-sniffer-based logger (optional). It captures API calls made to your pods over the wire, parses them and sends them to your Resurface pod.

## Values

The **etoken** value is a string equal to the password sent to you after signing up for Resurface.

    etoken: << paste it here! >>

The **service** value is where the configuration for both the **apiexplorer** and **flukeserver** can be found.
Both the exposed **port** and **type** of service can be configured with their corresponding interger and string values, respectively.

    service:
      apiexplorer:
        port: 7700
        type: LoadBalancer
      flukeserver:
        port: 7701
        type: ClusterIP

The **sniffer** value is where the configuration for the optional network packet sniffer can be found.
The sniffer can be deployed by setting the **deploy** value to **true**.
In addition, the application **port** to listen packets from must be specified.
The **device** to attach the sniffer to is an optional string, and it defaults to the kubernetes custom bridge interface **"cbr0"**.
The internal logger can be temporarily disabled by setting the **enabled** value to **false**.
Finally, this logger operates under a certain [set of rules](http://resurface.io/logging-rules) that determine which data is logged. These **rules** can be passed to the logger as a single-line (or a multiline) string.

    sniffer:
      deploy: true
      port: 80
      device: cbr0
      logger:
        enabled: true
        rules: |
          include debug
          skip_compression

## Single-node volatile storage configuration

Set the required values as indicated in the [values](#values) section. No further configuration is neeeded.

## Single-node persistent storage configuration

// Coming soon!

## Multi-node volatile storage configuration

// Coming soon!

## Multi-node persistent storage configuration

// Coming soon!
