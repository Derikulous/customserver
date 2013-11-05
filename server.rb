require 'socket' #Provides #TCPServer and TCPSocket classes
require 'uri'

# Files will be served publicly from this directory
WEB_ROOT = './public'

# Map extensions to their content type
CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}

# Treat as binary data if content type cannot be found
DEFAULT_CONTENT_TYPE = 'application/octet-stream'

# This helper function parses the extension of the
# requested file and then looks up its content type.

def content_type(path)
  ext = File.extname(path).split(".").last
  CONTENT_TYPE_MAPPING.fetch(ext, DEFAULT_CONTENT_TYPE)
end

# helper function that parses the Request-Line and generates a path to a file on the server
def requested_file(request_line)
  request_uri = request_line.split(" ")[1]
  path        = URI.unescape(URI(request_uri).path)

  clean = []

  parts = path.split("/") # Split the path into components

  parts.each do |part|
    next if part.empty? || part == '.' #skip and empty or current directory
    part == '..' ? clean.pop : clean << part # if the path goes up one level, remove the last clean component
  end

  File.join(WEB_ROOT, path) # Return the webt root joined to the clean path
end

# Initialize a TCPServer object that will listen on port 3232 for incoming connections
server = TCPServer.new('localhost', 3000)
puts " /\\_/\\\n( o.o ) \n > ^ <"

#loop infinitely, processing one incoming connection at a time

loop do
  socket = server.accept # Wait until a client connects, then return TCPSocket

  request_line = socket.gets # Reads the first line of the request socket = server.accept. Uses helper method

  STDERR.puts request_line # Log the request to the console for debugging

  path = requested_file(request_line)

  path = File.join(path, 'index.html') if File.directory?(path)

  # Check that the file exists before opening it
  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|

    # We need to include the Content-Type and Content-Length headers
    # to let the client know the size and type of data
    # contained in the response. Note that HTTP is whitespace
    # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")

    socket.print "HTTP/1.1 200 OK\r\n" +
                 "Content-Type: #{content_type(file)}\r\n" +
                 "Content-Length: #{file.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n" #Print a blank line to separate the header from the body
    IO.copy_stream(file, socket) # Write the contents of the file to the socket
  end
else
  message = "If you're here, then you must answer this question: Why am I here?\n"

    # respond with a 404 error code to indicate the file does not exist
    socket.print "HTTP/1.1 404 Not Found\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{message.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n"

    socket.print message
  end

  socket.close #Close the socket, terminating the connection
end
