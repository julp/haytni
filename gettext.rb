#!/usr/bin/env ruby

# Do not run directly this script but gettext.sh instead.
# The purpose of this script is to extract the strings to
# translate from the files of priv/**/* which
# `mix gettext.extract` doesn't even parse

require 'open3'

Match = Struct.new(:file, :line)

translations = {}
POT_FILE = "#{__dir__}/priv/gettext/haytni.pot"
GREP_REGEXP = '(Haytni\.Gettext\.)?dgettext\("haytni",\s*"[^"]*"(,\s*[[:alpha:]][[:alnum:]_]+:\s*[^,]+)*\)'

File.open(POT_FILE, 'r') do |file|
  pending = []
  while line = file.gets do
    case line.chomp
    when "#, elixir-format\n"
      # NOP: ignore
    when /^msgstr\s+"/
      # NOP: ignore
    when /^msgid\s+"(.*)"$/
      translations[$1] = pending # no need to unescape '"'?
      pending = []
    when /^#: (.+):(\d+)$/
      pending << Match.new($1, $2.to_i)
    end
  end
end

Open3.popen3("grep --color=never -HnorE '#{GREP_REGEXP}' #{__dir__}/priv/") do |stdin, stdout, stderr, wait_thr|
  while line = stdout.gets do
    file, line, string = line.split(':', 3)
    /(?:Haytni\.Gettext\.)?dgettext\("haytni",\s*"(?<msgid>[^"]*)"(?:,\s*[[:alpha:]][[:alnum:]_]+:\s*[^,]+)*\)/ =~ string
    translations[msgid] = [] unless translations.has_key?(msgid)
    translations[msgid] << Match.new(file, line.to_i)
  end
end

translations.delete('')
File.open(POT_FILE, 'w') do |file|
  file.write <<~EOS
    ## This file is a PO Template file.
    ##
    ## `msgid`s here are often extracted from source code.
    ## Add new translations manually only if they're dynamic
    ## translations that can't be statically extracted.
    ##
    ## Run `mix gettext.extract` to bring this file up to
    ## date. Leave `msgstr`s empty as changing them here as no
    ## effect: edit them in PO (`.po`) files instead.
    msgid ""
    msgstr ""

  EOS
  translations.each do |msgid, locations|
    file.write "#, elixir-format\n"
    locations.each do |location|
      file.printf("#: %s:%d\n", location.file, location.line)
    end
    file.write 'msgid "'
    file.write msgid # no need to escape '"'?
    file.write "\"\n"
    file.write "msgstr \"\"\n\n"
  end
end
