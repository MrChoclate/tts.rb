for line in $(find data_crawl/en/elizabeth_klett -iname "*.link"); do
  base="data_crawl/$(echo $line |cut -d '/' -f 2-3)";
  name=$(echo $line |cut -d '/' -f 4-4);
  zippath="$base/$name/$name.zip";
  mp3path="$base/$name/mp3";
  echo $zippath;
  cat $line|xargs curl -L > "${zippath}" && unzip "${zippath}" -d "${mp3path}"
done