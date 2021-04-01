resource "local_file" "create_script_for_making_master_ips_file" {
  depends_on=[module.workshop]
  filename = "bin/create_master_ips_file.sh"
  content = <<-EOF
    #!/bin/bash

    my_arr=(${join(" ", [for i in range(0,length(module.workshop)): module.workshop[i].master_ip])})

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
