module API;

import std.container : Array;

import std.array : array;
import std.array : split;

import std.process : executeShell;
import std.string : indexOf;

import std.algorithm : canFind, filter, map;

import Utils : showWarningMessagebox;
import Utils : showInfoMessagebox;
import Utils : readListFiles;
import Utils : logConsole;
import Crawler : Crawler;
import FileInfo : FileInfo;

// TODO: register delegate for messagebox show called from UI frontend library

class DrillAPI
{

private:
    Array!Crawler threads;
    immutable(string[]) blocklist;
    import std.regex;

    const(Regex!char[]) priority_regexes;
    immutable(string) drill_version;

public:

    this(immutable(string) exe_path)
    {
        debug
        {
            logConsole("exe_path: " ~ exe_path);
        }

        this.threads = Array!Crawler();
        import std.file : dirEntries, SpanMode, DirEntry, readText, FileException;
        import std.path : buildPath;

        string[] temp_blocklist = [];

        string version_temp = "?";
        try
        {

            temp_blocklist = readListFiles(buildPath(exe_path, "Assets/BlockLists"));
        }
        catch (FileException fe)
        {

            logConsole("Error when trying to load blocklists, will default to an empty list");
        }

        try
        {
            import std.array : join, replace;

            version_temp = replace(join(readText(buildPath(exe_path,
                    "DRILL_VERSION")).split("\n"), "-"), " ", "-");

        }
        catch (FileException fe)
        {
            version_temp = "LOCAL_BUILD";

            logConsole("Error when trying to read version number, will default to LOCAL_BUILD");
        }

        string[] temp_priority_list = [];
        try
        {

            temp_priority_list = readListFiles(buildPath(exe_path, "Assets/PriorityLists"));
        }
        catch (FileException fe)
        {
            logConsole("Error when trying to read priority lists, will default to an empty list");
        }

        this.blocklist = temp_blocklist.idup;

        this.priority_regexes = temp_priority_list[].map!(x => regex(x)).array;
        this.drill_version = version_temp;

    }

    /**
    Starts the crawling, every crawler will filter on its own.
    Use the resultFound callback as an event to know when a crawler finds a new result.
    You can call this without stopping the crawling, the old crawlers will get stopped automatically.
    If a crawling is already in progress the current one will get stopped asynchronously and a new one will start.

    Params:
        search = the search string, case insensitive, every word (split by space) will be searched in the file name
        resultFound = the delegate that will be called when a crawler will find a new result
    */
    void startCrawling(immutable(string) search, void delegate(immutable(FileInfo) result) resultFound)
    {
        this.stopCrawlingAsync();

        import std.algorithm : map;

        immutable string[] mountpoints = this.getMountPoints();

        foreach (string mountpoint; mountpoints)
        {
            // // debug
            // // {
            // //     log.info("Starting thread for: ", mountpoint);
            // // }
            Array!string crawler_exclusion_list = Array!string(blocklist);

            // for safety measure add the mount points minus itself to the exclusion list
            string[] cp_tmp = mountpoints[].filter!(x => x != mountpoint)
                .map!(x => "^" ~ x ~ "$")
                .array;
            // debug
            // {
            //     log.info(join(cp_tmp, " "));
            // }
            crawler_exclusion_list ~= cp_tmp;
            // assert mountpoint not in crawler_exclusion_list, "crawler mountpoint can't be excluded";

            import std.regex;

            // debug
            // {
            //     log.info("Compiling Regex...");
            // }
            const(Regex!char[]) exclusion_regexes = crawler_exclusion_list[].map!(x => regex(x))
                .array;

            // debug
            // {
            //     log.info("Compiling Regex... DONE");
            // }
            auto crawler = new Crawler(mountpoint, exclusion_regexes,
                    priority_regexes, resultFound, search);
            crawler.start();
            this.threads.insertBack(crawler);
        }
    }

    /**
    Notifies the crawlers to stop.
    This action is non-blocking.
    If no crawling is currently underway this will do nothing.
    */
    void stopCrawlingAsync()
    {
        foreach (Crawler crawler; this.threads)
        {
            crawler.stopAsync();
        }
        this.threads.clear(); // TODO: if nothing has a reference to a thread does the thread get GC-ed?
    }

    void stopCrawlingSync()
    {
        stopCrawlingAsync();
        waitForCrawlers();
    }

    void waitForCrawlers()
    {
        foreach (Crawler crawler; this.threads)
        {
            crawler.join();
        }
    }

    /**
    Returns the mount points the crawlers will scan when started with startSearch

    Returns: immutable array of full paths
    */
    immutable(string[]) getMountPoints()
    {
        version (linux)
        {
            // df catches network mounted drives like NFS
            // so don't use lsblk here
            immutable auto ls = executeShell("df -h --output=target");
            if (ls.status != 0)
            {
                showWarningMessagebox("Can't retrieve mount points, will just scan '/'");
                return ["/"];
            }
            immutable auto result = array(ls.output.split("\n").filter!(x => canFind(x, "/"))).idup;
            return result;
        }

        version (OSX)
        {
            immutable auto ls = executeShell("df -h");
            if (ls.status != 0)
            {
                showWarningMessagebox("Can't retrieve mount points, will just scan '/'");

                return ["/"];
            }
            immutable auto startColumn = indexOf(ls.output.split("\n")[0], 'M');
            immutable auto result = array(ls.output.split("\n").filter!(x => x.length > startColumn)
                    .map!(x => x[startColumn .. $])
                    .filter!(x => canFind(x, "/"))).idup;
            return result;
        }

        version (Windows)
        {
            //TODO fix this
            immutable auto ls = executeShell("wmic logicaldisk get caption");
            if (ls.status != 0)
            {
                showWarningMessagebox("Can't retrieve mount points, will just scan 'C:'");
                return ["C:"];
            }
            import std.algorithm : map;

            immutable auto result = array(map!(x => x[0 .. 2])(ls.output.split("\n")
                    .filter!(x => canFind(x, ":")))).idup;
            return result;
        }
    }

    /**
    A crawler is active when it's scanning something.
    If a crawler cleanly finished its job it's considered not active.
    If a crawler crashes (should never happen) it's not considered active.

    Returns: number of crawlers active
    */
    immutable(ulong) getActiveCrawlersCount() const
    {
        return array(this.threads[].filter!(x => x.isCrawling())).length;
    }

    /**
    Returns the version of Drill
    */
    pure immutable(string) getVersion() const @safe @nogc
    {
        return this.drill_version;
    }

}