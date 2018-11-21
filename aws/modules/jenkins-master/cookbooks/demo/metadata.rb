name 'demo'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'All Rights Reserved'
description 'Installs/Configures demo'
long_description 'Installs/Configures demo'
version '0.1.0'
chef_version '>= 12.4.1' if respond_to?(:chef_version)

depends 'java', '~> 2.1.0'
depends 'jenkins', '~> 6.2.1'
depends 'docker', '~> 4.6.7'
depends 'terraform', '~> 2.1.1'
depends 'postgresql', '= 2.1.0'