Place the already-prepared Kickstart files here, or change KICKSTART_DIR and the
VM_*_KS values in lab.conf:

deployment.ks
controller.ks
compute1.ks
compute2.ks
block1.ks

The Kickstart network device selection must match the NIC order in
VM_*_NETWORKS. The scripts do not rewrite or generate Kickstart files.
