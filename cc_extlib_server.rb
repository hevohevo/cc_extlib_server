####################################################
# CC_Extlib_Server
# (Web API server to provide some extention libraries for ComputerCraft)
# hevohevo@gmailcom
# version 0.1

# ChangeLog:
#  - 0.1: provide digest libraries: sha1, md5

=begin rdoc
Prameters(GET or POST): text, key, algorithm is utf-8
 - text: Anything is OK
 - key: Certification key. See KEY variables in this program.
 - algorithm: "sha1" or "md5". This is optional, and the default value is "sha1"
Return: text/plain, utf-8
 The data-type is a tabel for Lua
 
Sample1: (Require a KEY)
 http://localhost/digest?text=hello&key=iloveturtle&algorithm=md5
Result1:
 {result="aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d", parameter={text="hello", algorithm="md5"}}
 
Sample2: (Does not require a KEY)
 http://localhost/digest?text=hogehoge
Result2:
 {result="aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d", parameter={text="hello", algorithm="sha1"}}
=end

######################################################
require 'webrick'
require 'digest/md5'
require 'digest/sha1'
require 'kconv'

######################################################
## CONFIG
IP       = '127.0.0.1' # DON'T CHANGE!! Opening to the web is very DANGER!!
PORT     = '10080'
LOG_FILE = 'log.txt'

# If KEY is false or empty-str, this program does not require key.
KEY = 'iloveturtle'

######################################################
## FUNCTIONS

ALGO_TYPE = ["md5","sha1"]

def digest(s, algo)
  if algo == 'md5'
    return Digest::MD5.hexdigest(s)
  else
    return Digest::SHA1.hexdigest(s)
  end
end

def result_to_luatable(result,q_text,q_algo)
  doc=<<EOF
{result="#{result}", parameter={text="#{q_text}", algorithm="#{q_algo}"}}
EOF
end

def certificated?(key, q_key)
  if not key or key.empty?
    return true
  else
    return key == q_key
  end
end

class DigestProc < WEBrick::HTTPServlet::AbstractServlet
  def same_proc(req,res)
    result = nil
    q_text = req.query.key?('text') ? req.query['text'] : false
    q_algo = ALGO_TYPE.index(req.query['algorithm']) ? req.query['algorithm'] : "sha1"
    q_key = req.query.key?('key') ? req.query['key'] : nil
    
    if not certificated?(KEY, q_key)
      res.status = 403
      result = "Authorization failed."
    else
      if q_text
        if q_text.isutf8
          res.status = 200
          result = digest(q_text, q_algo)
        else
          res.status = 400
          result = "Required: 'UTF-8' text"
        end
      else
        res.status = 400
        result = "Required: Text"
      end      
    end
    
    
    res.body = result_to_luatable(result, q_text, q_algo)
    res.content_type = "text/plain; charset=UTF-8"
  end
  
  def do_POST(req, res)
    same_proc(req,res)
  end

  def do_GET(req, res)
    same_proc(req,res)
  end
end


######################################################
## MAIN
opts  = {
  :BindAddress    => IP,
  :Port           => PORT,
  :Logger => WEBrick::Log::new(LOG_FILE, WEBrick::BasicLog::DEBUG)
}
server = WEBrick::HTTPServer.new(opts)

server.mount("/digest", DigestProc)

Signal.trap(:INT){server.shutdown}
server.start