mcollective-plugin-file_stage
=============================

# Usage

## Stage Action

The stage action is used to start a staging operation.

#### Required Parameters

**source**
The source parameter is used to indicate from where the filestage plugin
will retrieve a file. It can be a fully qualified file path locally on
the system or a URI to a file in a remote location. The supported
protocols for transfer are HTTP and FTP (future, not yet available).

When using HTTP to transfer the file, a direct link to the file must be
provided. The filestage plugin will not follow redirects.

**dest**
The location on the system where the file will be staged to. This
location must be a fully qualified file path.

#### Optional Parameters

**force**
If force is set to 'true' it will cause filestage to overwrite any file
at a destination if it already exists.

#### Example Usage
This example will download the robots.txt file from whitehouse.gove and
replacing whatever is at /tmp/secrets on the machine performing the stage
operation.
```
peadmin@master:/root$ mco rpc filestage stage source=http://www.whitehouse.gov/robots.txt dest=/tmp/secrets force=true
```

## Status Action

The status action is used to see the state of current and past staging
operations.

#### Optional Parameters

**dest**
If provided, the status action will focus on the most recent status, as
the same location could be staged to more than once, of a staging
operation that placed a file in the destination specified. If no
status if found for a file in that location, none will be displayed.

Keep in mind, there is no gaurentee that the file is still in the
location, or has not been modified or replaced manually. This is simply
the status and result of what the filestage plugin did.

If no 'dest' parameter is displayed, then all the staging statuses that
can be found will be displayed in ascending order.

#### Example Usage

```
peadmin@master:/root$ mco rpc filestage status  dest=/tmp/secrets -v
```
