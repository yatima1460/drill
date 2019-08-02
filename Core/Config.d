




// immutable(string) DEFAULT_BLOCK_LIST    = import("BlockLists.txt");
// immutable(string) DEFAULT_PRIORITY_LIST = import("PriorityLists.txt");

// TODO: load and save config in ~/.config


@safe @nogc pure struct DrillConfig
{
    string ASSETS_DIRECTORY;
    invariant
    {
        assert(ASSETS_DIRECTORY !is null);
        assert(ASSETS_DIRECTORY.length > 0);
    }
    string[] BLOCK_LIST;
    string[] PRIORITY_LIST;

    import std.regex: Regex;
    Regex!char[] PRIORITY_LIST_REGEX;
    invariant
    {
        assert(PRIORITY_LIST_REGEX.length == PRIORITY_LIST.length);
    }
    bool singlethread;
}

version (linux)
    {
/**
Returns the path where the config data is stored
*/
public string getConfigPath()
{
    
        import std.path : expandTilde;
        return expandTilde("~/.config/drill-search");
    

}
} 


// private void createDefaultConfigFiles()
// {
//     import std.path : buildPath;
//     import std.file : write; 
//     import std.array : join;
//     import std.path : baseName;

//     write(buildPath(getConfigPath(),"BlockList.txt"), DEFAULT_BLOCK_LIST); 
//     write(buildPath(getConfigPath(),"PriorityList.txt"), DEFAULT_PRIORITY_LIST); 
// }




// string[] loadBlocklists()
// {

// }


/*
Loads Drill data to be used in any crawling
*/
DrillConfig loadData(immutable(string) assetsDirectory)
{
    import std.path : buildPath;
    import std.conv: to;
    import std.experimental.logger;

    import Utils : mergeAllTextFilesInDirectory;
    import std.file : dirEntries, SpanMode, DirEntry, readText, FileException;
    import Utils : getMountpoints;
    import Meta : VERSION;
    import std.regex: Regex, regex;
    import std.algorithm : canFind, filter, map;
    import std.array : array;
    
    //Logger.logDebug("DrillAPI " ~ VERSION);
    //Logger.logDebug("Mount points found: "~to!string(getMountpoints()));
    auto blockListsFullPath = buildPath(assetsDirectory,"BlockLists");

    info("Assets Directory: " ~ assetsDirectory);
    info("blockListsFullPath: " ~ blockListsFullPath);

    string[] BLOCK_LIST; 
    try
    {
        BLOCK_LIST = mergeAllTextFilesInDirectory(blockListsFullPath);
    }
    catch (FileException fe)
    {
        error(fe.message);
        error("Error when trying to load block lists, will default to an empty list");
    }

    string[] PRIORITY_LIST;



    Regex!char[] PRIORITY_LIST_REGEX;
    try
    {
        PRIORITY_LIST = mergeAllTextFilesInDirectory(buildPath(assetsDirectory,"PriorityLists"));

       
        PRIORITY_LIST_REGEX = PRIORITY_LIST[].map!(x => regex(x)).array;
    }
    catch (FileException fe)
    {
        error(fe.message);
        error("Error when trying to read priority lists, will default to an empty list");
    }
    // DrillConfig dd;
    DrillConfig dd = {
        assetsDirectory,
        BLOCK_LIST,
        PRIORITY_LIST,
        PRIORITY_LIST_REGEX,
        false
    };
    return dd;
}