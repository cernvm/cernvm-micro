Cluster contextualization
=========================

Distribution of master data (IP address) to slaves via a single point. The master data is
applied before the usual contextualization is done.

Usage
-----
1. Create or get a context file for your machines.
2. Go to the [Cluster Pairing Service](https://cernvm-online.cern.ch/cluster_pairing) and generate a new cluster pairing pin.
3. Enter this as `cvm_cluster_pin` in the `ucernvm` section of your context file.
4. Create a context file for your master machine by adding `cvm_cluster_master=yes` to the `ucernvm` section
   of the original context file.
5. Create a context file for your slave machine(s). You must place the `###MASTER_IP_PLACEHOLDER###` string
   in this file, to the location where the master's IP address should be placed.
6. Launch a master VM.
7. Launch slave VMs.

### Master context file example

    [amiconfig]
    plugins=cernvm

    [cernvm]
    organisations=ATLAS
    shell=/bin/bash
    config_url=http://cernvm.cern.ch/config
    users=atlas:atlas:$6$4ZctFHqh$9kZHLCHVUvWBs76SjWxN2QfN.vATu7/AWh1dsVV8PRqm6UdBCvcPG8YVE4epYV2dVMg.nJxG1yqbi/8q8VPhO1
    edition=Desktop
    screenRes=1280x700
    keyboard=us
    startXDM=on

    [ucernvm-begin]
    cvm_cluster_master=yes
    cvm_cluster_pin=enico1qq0oey
    [ucernvm-end]

### Slave context file example

    [example_section]
    my_master_ip=###MASTER_IP_PLACEHOLDER###

    [amiconfig]
    plugins=cernvm

    [cernvm]
    organisations=ATLAS
    shell=/bin/bash
    config_url=http://cernvm.cern.ch/config
    users=atlas:atlas:$6$4ZctFHqh$9kZHLCHVUvWBs76SjWxN2QfN.vATu7/AWh1dsVV8PRqm6UdBCvcPG8YVE4epYV2dVMg.nJxG1yqbi/8q8VPhO1
    edition=Desktop
    screenRes=1280x700
    keyboard=us
    startXDM=on

    [ucernvm-begin]
    cvm_cluster_pin=enico1qq0oey
    [ucernvm-end]

As you can see, the master and slave context files only differ in the content of the `ucernvm` section, where
the master context has an additional field `cvm_cluster_master=yes`.


### Available cluster contextualization fields in the context file

These have to be placed in the `ucernvm` section of the context file.

- `cvm_cluster_pin`: cluster contextualization PIN, acquired from the
  [cluster service](https://cernvm-online.cern.ch/cluster_pairing), which is needed for correct master/slave identification.
  This key automatically expires after 24 hours, so you need to launch your machines before.
- `cvm_cluster_master`: whether the context file is for the master or not.
- `cvm_service_url`: URL of the service you want to use for the synchronization. Defaults to
  `https://cernvm-online.cern.ch`. You may specify the port as well, e.g. `my-service.example.com:8000`.
    

Architecture
------------

There are two components:

1. Cluster contextualization service, which stores and provides the data.
2. Contextualization *agents* `amiconfig` and `cloud-init` to process the data.

### Cluster contextualization service

This is a lightweight Django application, currently residing at [cernvm-online.cern.ch](https://cernvm-online.cern.ch).
If you want implement your own service, it must respect the REST API (see below).

### Contextualization agents

**Amiconfig** contextualization agent performs the data fetching and replacement in the bootloader phase.
It consists of one file (`scripts.d/08clustercontext`) in the [cernvm-micro repository](https://github.com/cernvm/cernvm-micro/).

**Cloud-init** contextualization agent performs the data fetching and replacement before the cloud-config
phase (for the cloud-init service). It also submits the `master_ready` status, when master bootup is completed (and slaves can
start fetching the data).

It consists of two systemd services: `cernvm-cluster-contextualization`, which performs the
data fetching and replacement in the cloud-config context file, and `cernvm-master-ready` that sends a `master_ready`
status to the service (when run on a master).

### Data flow

1. Master VM is created with the master context.
2. It pushes its data (IP address) to the REST service under the `cvm_cluster_pin` provided in the context file.
3. Slave VMs are created with the slave context.
4. Slaves fetch the master data (IP address) from the REST service, stored under the `cvm_cluster_pin` provided
   in the context file.
5. Slaves finish their boot process.


REST API of the cluster contextualization service
-------------------------------------------------
    
### Endpoint: `/api/v1/clusters`

**POST** (accepts no data)

    {
    }

Returns newly created cluster pin:

    {
        "pin": "string",
        "creation_time": "datetime"
    }


### Endpoint: `/api/v1/clusters/<cluster_pin>`

**GET**

Returns info about the cluster pin:

    {
        "pin": "string",
        "creation_time": "datetime"
    }

**DELETE**

Delete the given cluster pin.


### Endpoint: `/api/v1/clusters/<cluster_pin>/keys`

**GET** 

Returns list of keys (items) saved for the given cluster pin:

    [
        {
            "key": "master_ip",
            "value": "10.10.25.5"
        }
    ]

**POST**

    {
        "key": "key_of_the_item",
        "value": "item_value"
    }

Returns newly created item:

    {
        "key": "key_of_the_item",
        "value": "item_value"
    }


### Endpoint: `/api/v1/clusters/<cluster_pin>/keys/<key_name>`

**GET** 

Returns info about key (item) for the given cluster item.

By default uses `plain/text` content type:
    
    master_ip: 10.10.25.5

You can request JSON by setting the `Accept` header to `application/json`:

    {
        "key": "master_ip",
        "value": "10.10.25.5"
    }


**PUT**, **PATCH**

Modify the key (item).


    {
        "key": "key_of_the_item",
        "value": "item_value"
    }


**DELETE**

Delete the given cluster pin.
