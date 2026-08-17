package main

import rego.v1

# Deny any Deployment whose container image uses the ":latest" tag
deny[msg] {
  input.kind == "Deployment"
  image := input.spec.template.spec.containers[_].image
  endswith(image, ":latest")
  msg := sprintf("Image %q must not use the ':latest' tag", [image])
}