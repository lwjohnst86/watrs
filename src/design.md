# Design

This document outlines the design principles and interface for the `waltrs` time
tracker, as well as some differences from the original Watson. This document is
mainly a way to help keep me focused on what to actually implement and when I
will know what "done" looks like.

## Princples

My main aim is to build a simplified version of the
[Watson](https://github.com/jazzband/watson) time tracker. And I want to follow
a few principles to guide the design of it:

- Empower the user to be familiar with their data by encouraging them to
  interact directly with the timesheet data, e.g. via the terminal or editor.
- Save timesheet data in a format and structure that is human-readable and
  editable.
- Structure timesheet data to be importable by different tools (for other
  analyses).
- Assume Git will be used to keep backups.
- Have a simple interface with a few actions.
- Keep timesheet statistics to a minimal, instead referring to use other
  specialised tools for more advanced analyses.
- Output statistics to the terminal in a table format (columns and rows).

## Interface

### `start [<project>] [<tags>]`

Has the CLI signature `start [<project>] [<tags>]`. Starts the timer for a given
project with optional tags. Creates a new entry in the timesheet file with an
empty `stop` field. If a timer is already running for a different project, it
will stop the timer on the other project and start a new one for the given
project. If no project is given, it defaults to starting the last project (along
with the same tags used).

It will not add a new entry if the timesheet file can't be parsed/read, if there
are duplicate `id` values, or if there are `start` entries later than the `stop`
entries (`stop` is earlier than `start`).

### `stop`

Stops the current timer. Adds a timestamp to the `stop` value in the timesheet
file with an entry that has an empty `stop` value. It will only stop and add the
timestamp if there is a timer running (the most recent `start` timestamp without
a `stop` timestamp). Can't stop if the current `start` entry is in the future
(e.g. if the person incorrectly edited the file).

It has the same constraints as `start` for when it won't work.

### `edit`

Opens the timesheet file in the user's editor (e.g. `vim`) for them to edit
themselves. Use this to fix a mistake in an entry, remove an entry, fix a merge
conflict, or cancel the currently running entry. Since this will "simply" open
the file in the default editor, going to the necessary entry can be done by
searching for the timestamp, project or tag, or going to the end of the file for
the most recent entry.

If you edit the file, it will only save if it passes the same constraints as the
`start` command.

### `stats [<subcommand>] [<options>]`

Has the CLI signature `stats [<subcommand>] [<options>]`. This command contains
several subcommands that provide basic statistics for various aspects of the
timesheet data.

- `projects`: Lists all projects with the total time spent for each project.
  Options include `--unit <unit>` to specify the unit of time to display (only
  units bigger than `day`, which is the default), `--number-of-units <n>` to
  show the `n` number of units the the statistics (e.g. `--number-of-units 3` to
  show the last 3 days), as well as `--include-tags` to include the time spent
  on each tag within each project, grouped by the unit.

- `tags`: Lists all tags with the total time spent for each tag. Options include
  the `--unit` and `--number-of-units` found in `projects`.

### `today`

Mainly is a helper command to get an idea about the day. Lists the entries for
the current day, including the entry that is currently running.

### `WALTRS_TIMESHEET_PATH`

`WALTRS_TIMESHEET_PATH`: Environment variable to set the location of the
timesheet. If not set, it defaults to `~/.waltrs/timesheet.json`.

## Data

Data is stored in a JSON file, found in the file provided by
`WALTRS_TIMESHEET_PATH`. All entries have fields with keys for `id`, `start`,
`stop`, `project`, and `tags`. The `id` is a unique identifier for the entry,
generated using an UUID and is used to ensure an identifiable entry for
analyses. The `start` and `stop` fields are in ISO 8601 format (stored in UTC
timezone), which is a standard for representing date and time (without
microseconds). All fields can be imported as strings.

While including both field keys and a character string for date will make the
file larger, it also makes it easier to read and edit. And given that Polars
will be reading from the file, size isn't really a computational concern nor is
it a concern for disk storage as most modern computers have plenty of storage
space. At the cost of a larger file size, the benefit is a more human-readable
and -editable structure.

The JSON structure looks a bit like this, *for each timesheet entry*:

``` json
{
  "id": "unique-id-12345",
  # Following the ISO 8601 format for date and time
  "start": "2023-10-01T12:00:00Z",
  "stop": "2023-10-01T14:00:00Z",
  "project": "example_project",
  "tags": ["tag1", "tag2"]
}
```

Since the data is structured as a JSON file with clear keys and all strings,
doing further analyses or wrangling on it is as easy as reading it with
[Polars](https://pola.rs) (or [DuckDB](https://duckdb.org)) via Python, R, or
the shell.

## Differences from Watson

### Data format

Watson stored it's data in a `[]` bracketed JSON file, with fields that had
values but no keys (they were unnamed). So that means if you wanted to directly
edit the file, you would have to know the order of the fields. This is not very
user-friendly, especially if you e.g. have a merge conflict from using Git to
track your timesheet. It also made it much more difficult to read into other
analysis tools.

### Commands

Some commands in Watson I almost never used or always misunderstood their
action/how to use them, where I often had to review the documentation multiple
time just to use and (re)learn it (e.g. `report` vs `aggregate`). I decided to
drop or heavily modify/merge many commands:

- Dropped: `restart`, `sync`, `help` (that's built into the Rust CLI), `merge`,
  `frames`, `add`
- Merged/modified into `stats`: `report`, `aggregate`, `status`, `projects`,
  `tags`
- Merged/modified into `edit`: `edit`, `cancel`, `remove`

### Options

Most Watson commands had several options or behaviours for each command that I
rarely used, nor liked. So I decided to:

- Remove all "confirm new project/tags" options/behaviour, such as in `start`
  and `stop`.
