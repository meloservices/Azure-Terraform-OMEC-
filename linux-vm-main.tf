# Template for bootstrapping
data "template_file" "linux-vm-cloud-init" {
  template = file("azure-user-data.sh")
}
