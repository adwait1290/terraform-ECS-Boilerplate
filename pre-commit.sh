#!/bin/bash
set -ex
terraform fmt -check=true ./base
terraform fmt -check=true ./environment/development