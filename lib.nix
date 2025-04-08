rec {
  downloadMusic = { name, provider, link, filename, ... }:

    if name == "test" then
      throw "I do not allow testing here!"
    else
      let
        inherit name;
        inherit filename;
        inherit provider;
        inherit link;

      in "nom: ${name}, prov: ${provider}, link: ${link}, fname: ${filename}";

  init = args@{ home, entries }:
    let
      home = args.home;
      entries = args.entries;
    in "";

  # Create the file path
  # Will throw an exception
  # if requesting a filepath sorted by extension
  # without providing an extension
  createFilePath = set@{ category, name, sortByExtension, ... }:
    if sortByExtension then
      if builtins.hasAttr "extension" set then
        if builtins.hasAttr "author" set then
          "./${category}/${set.author}/${set.extension}/${name}"
        else
          "./${category}/${set.extension}/${name}"
      else
      # provided `sosortByExtension` as true without
      # providing an extension
        throw ''
          Expecting to sort by extension without providing one, 
                please provide an `extension` attribute''
    else if builtins.hasAttr "author" set then
      "./${category}/${set.author}/${name}"
    else
      "./${category}/${name}";

  # Attribute set for a categorized music file:
  # {
  #   name: String;
  #   category: String;
  #   link: String;
  #   groupByExtension: bool;
  #   hash: string; ? maybe remove soemhow
  #   Override: ???;
  # }
  handleFileListRecursion = { list, accum, index }:
    if builtins.length list - 1 < index then
      accum
    else
      let
        entry = builtins.elemAt list index;

        name = entry.name;
        url = entry.link;
        category = if builtins.hasAttr "category" entry then
          entry.category
        else
          "uncategorized";

        sortByExtension = if builtins.hasAttr "sortByExtension" entry then
          entry.sortByExtension
        else
          false;

        hash = entry.hash;

        # create our filepath
        # for home-manager
        path = createFilePath {
          inherit category;
          inherit name;
          inherit sortByExtension;
        };

        # declare function
        # it creates a new accumulator set
        # downloads the file
        # and calls the `handleFileListRecursion` function
        # to iterate recursively through the provided list
        func = { filepath, accum, url }:
          let
            newSet = accum // downloadFile {
              inherit url;
              sha256 = hash;
              name = filepath;
            };
          in handleFileListRecursion {
            inherit list;
            accum = newSet;
            index = index + 1;
          };

      in func {
        filepath = path;
        inherit accum;
        inherit url;
      };

  handleFileList = list:
    handleFileListRecursion {
      inherit list;
      accum = { };
      index = 0;
    };

  downloadFile = { url, sha256, name }: {
    file."${name}".source = builtins.fetchurl {
      inherit url;
      inherit sha256;
    };
  };
}
