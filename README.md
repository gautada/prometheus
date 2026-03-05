# prometheus

[Prometheus](http://prometheus.io) is an open-source systems monitoring and
alerting toolkit originally built at SoundCloud. Since its inception in 2012,
many companies and organizations have adopted Prometheus, and the project has
a very active developer and user community. It is now a standalone open source
project and maintained independently of any company. To emphasize this, and to
clarify the project's governance structure, Prometheus joined the Cloud Native
Computing Foundation in 2016 as the second hosted project, after Kubernetes.

Prometheus collects and stores its metrics as time series data, i.e. metrics
information is stored with the timestamp at which it was recorded, alongside
optional key-value pairs called labels.

[Repository](https://github.com/prometheus/prometheus)

## Container

### Versions

- [September 8, 2021](https://prometheus.io/download/) - Active version is
  2.29.2 as tag [2.29.2](https://github.com/prometheus/prometheus/tags)

### Manual Build

```
docker build --build-arg ALPINE_TAG=3.14.1 --build-arg BRANCH=v2.29.1 \
             --tag prometheus:dev -f Containerfile . 
docker run -i -p 9090:9090 -t --name prometheus --rm prometheus:dev
```

## Nodes

One of the primary reasons for installing prometheus is to monitor and track
the individual nodes.

[No bare](https://blog.alexellis.io/prometheus-nodeexporter-rpi/)
