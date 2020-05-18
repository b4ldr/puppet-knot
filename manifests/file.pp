# Define: knot::file
#
define knot::file (
    String                       $ensure           = 'present',
    String                       $owner            = 'knot',
    String                       $group            = 'root',
    Pattern[/^\d+$/]             $mode             = '0660',
    Optional[String]             $origin           = undef,
    Optional[Stdlib::Filesource] $source           = undef,
    Optional[String]             $content          = undef,
    Optional[String[1]]          $content_template = undef,
) {
  include ::knot
  if $content and $content_template {
    fail('can\'t set $content and $content_template')
  } elsif $content {
    $_content = $content
  } elsif $content_template {
    $_content = template($content_template)
  } else {
    $_content = undef
  }
  if defined('$::knot_version') and versioncmp($::knot_version, '2.3.0') >= 0 {
    if $origin {
      $validate_cmd = "${::knot::kzonecheck_bin} -o ${origin} %"
    } else {
      $validate_cmd = "${::knot::kzonecheck_bin} %"
    }
  } else {
    $validate_cmd = undef
  }
  file { "${::knot::zone_subdir}/${title}":
    ensure       => $ensure,
    owner        => $owner,
    group        => $group,
    mode         => $mode,
    source       => $source,
    content      => $_content,
    validate_cmd => $validate_cmd,
    require      => Package[$::knot::package_name],
    notify       => Service[$::knot::service_name];
  }
}

