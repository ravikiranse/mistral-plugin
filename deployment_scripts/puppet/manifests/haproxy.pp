notice('MODULAR: mistral/haproxy.pp')

$network_metadata       = hiera_hash('network_metadata')
$mistral_hash           = hiera_hash('fuel-plugin-mistral', {})
# enabled by default
$use_mistral            = pick($mistral_hash['metadata']['enabled'], true)
$public_ssl_hash        = hiera('public_ssl')

$mistral_address_map    = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['mistral']), 'mistral/api')

if ($use_mistral) {
  $server_names         = hiera_array('mistral_names', keys($mistral_address_map))
  $ipaddresses          = hiera_array('mistral_ipaddresses', values($mistral_address_map))
  $public_virtual_ip    = hiera('public_vip')
  $internal_virtual_ip  = hiera('management_vip')

  # configure mistral ha proxy
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }

  openstack::ha::haproxy_service { 'mistral-api':
    order               => '220',
    listen_port         => 8989,
    internal            => true,
    public              => true,
  }
}
