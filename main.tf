module "workshop" {
  source = "./modules/workshop"
  count = var.cluster_count
  cluster_name = "learning-cluster"
  tags = var.tags
  aws_instance_root_size_gb = var.aws_instance_root_size_gb
  flannel_version = var.flannel_version
  module_pass = count.index
  instance_type = var.instance_type
}

resource "local_file" "create_script_for_making_master_ips_file" {
  filename = "bin/create_master_ips_file.sh"
  content = <<-EOF
    #!/bin/bash

    my_arr=(${join(" ", ["192.192.192.192","168.168.168.168"])})

    # get the directory containing the script, irregardless of where the script is called from
    DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    BIN_DIR="$DIR" # bin_dir = directory containing the script

    if [[ -f  "$BIN_DIR/master_ips.txt" ]]; 
    then
        echo "Oops, the file $${BIN_DIR}/master_ips.txt.old already exists! Renaming the file to ./bin/master_ips.txt.old. Deleting the file ./bin/master_ips.txt.old if it exists, also...."
        if [[ -f "$BIN_DIR/master_ips.txt.old" ]]; 
        then 
            rm "$BIN_DIR/master_ips.txt.old"
        fi 
        mv "$BIN_DIR/master_ips.txt" "$BIN_DIR/master_ips.txt.old" 
    fi

    for i in $${my_arr[@]}
    do
      echo $i >> "$BIN_DIR/master_ips.txt"
    done

    echo "successfully added $${#my_arr[@]} ip addresses to ./bin/master_ips.txt"
  EOF
}

resource "null_resource" "create_master_ips_file" {
  depends_on = [local_file.create_script_for_making_master_ips_file]
  provisioner "local-exec" {
    command = "chmod +x ./bin/create_master_ips_file.sh && ./bin/create_master_ips_file.sh"
  }
}