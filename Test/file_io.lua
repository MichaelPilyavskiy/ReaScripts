  function file_cut(src_path, dest_path)
    
    file = io.open (src_path, 'r')
    content = file:read("*all")
    io.close (file)
    
    file = io.open (dest_path, 'w')
      file:write(content)
    io.close (file)
    
    os.remove(src_path)
        
  end
