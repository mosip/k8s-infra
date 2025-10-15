# Automating Rancher RoleTemplates

A simple, idempotent approach to create/update multiple Rancher RoleTemplate objects in bulk using the Rancher HTTP API (curl) or kubectl on the Rancher management cluster.

## Overview

This automation does the following:

Reads multiple RoleTemplate definitions (JSON or YAML) from a roles/ folder.

For each definition: checks if the RoleTemplate exists in Rancher.

If not present → creates it (POST /v3/roletemplates).

If present → Ignores the role.

## Prerequisites

Set environment variables mentioned below:
* export RANCHER_URL="https://rancher.example.com"
* export TOKEN="token-xxxxx:yyyyyyyy"`

Note: Each file in roles/ is a valid Rancher RoleTemplate JSON payload.

## Rancher-role-creator.sh

This script loops over files in roles/, checks if a RoleTemplate with the same name exists, and creates or updates accordingly.

Key behaviors:

Query /v3/roletemplates?name={name} to see if an object exists.

POST /v3/roletemplates to create.

PUT /v3/roletemplates/{id} to update (replace). If you prefer partial updates use PATCH.

Make sure the script has execute permission.

