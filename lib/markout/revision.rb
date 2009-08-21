require 'rdiscount'
require 'cgi'

module Markout

  class Revision

    attr_reader :sha, :date, :author, :subject

    def initialize(path, repo, commit)
      @repo   = repo
      @sha    = commit.sha
      @date   = commit.date
      @author = commit.author.to_s
      @subject, @message = parse_commit_message(commit)
      @path   = path
      @diff   = if right_diff = commit.show.detect {|diff| diff.a_path == @path}
                   CGI.escapeHTML(right_diff.diff)
                else
                  ''
                end
    end

    def diff(options={})
      case options[:format]
        when 'raw'    then @diff
        when 'short'  then short_diff
        when 'inline' then inline_diff
        else @diff
      end
    end

    def message(options={})
      case options[:format]
      when :html
        return RDiscount.new( CGI::escapeHTML(@message) ).to_html
      else
        return @message
      end
    end

    private

    def parse_commit_message(commit)
      lines = commit.message.split("\n")
      [ lines.first, lines[1..commit.message.size].join("\n") ]
    end

    def short_diff
      @diff.gsub(/^\-\-\- a\/\S+\n+/, '').
            gsub(/^\+\+\+ b\/\S+\n+/, '').
            gsub(/^\-\-\- \/dev\/null\n+/, '').
            gsub(/^\+\+\+ \/dev\/null\n+/, '').
            gsub(/^@@ .+\n+/,   '')
    end

    def inline_diff
      # FIXME: Cleanup
      output  = %x[cd #{@repo.path} && git show --no-prefix --ignore-space-at-eol --color-words #{@sha} -- #{@path} 2>&1]
      puts output
      puts '=============================='
      if $?.success?
        return convert_bash_color_codes( output )
      else
        return short_diff
      end
    end

    # Lifted from Integrity (www.integrityapp.com), (c) foca & sr
    def convert_bash_color_codes(string)
      string = CGI.escapeHTML(string)
      string.
        gsub(/.*index 0000000.*$/m, '').
        gsub(/(.*)@@(.*)/m, '\2').
        gsub(/\e\[31m([^\e]*)\e\[m/, '<del>\1</del>').
        gsub(/\e\[32m([^\e]*)\e\[m/, '<ins>\1</ins>').
        gsub("\e[m", '')
    end

  end

end
