echo "cookbook_path \"`pwd`\"" > solo.rb

curl -L https://www.opscode.com/chef/install.sh | bash
/usr/bin/chef-solo -j ./chef.json -c ./solo.rb
