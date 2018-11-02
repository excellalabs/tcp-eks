name 'bench-demo'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'All Rights Reserved'
description 'Installs/Configures bench-demo'
long_description 'Installs/Configures bench-demo'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'java', '~> 2.1.0'
depends 'jenkins', '~> 6.0.0'
depends 'docker', '~> 4.3.0'
depends 'terraform', '~> 2.1.1'
depends 'postgresql', '= 2.1.0'