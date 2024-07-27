const print = @import("std").debug.print;

const TripError = error{ Unreachable, EatenByAGrue };

const Place = struct {
    name: []const u8,
    paths: []const Path = undefined,
};

var a = Place{ .name = "Archer's Point" };
var b = Place{ .name = "Bridge" };
var c = Place{ .name = "Cottage" };
var d = Place{ .name = "Dogwood Grove" };
var e = Place{ .name = "East Pond" };
var f = Place{ .name = "Fox Pond" };

const place_count = 6;

const Path = struct {
    from: *const Place,
    to: *const Place,
    dist: u8,
};

const a_paths = [_]Path{
    Path{ .from = &a, .to = &b, .dist = 2 },
};

const b_paths = [_]Path{
    Path{ .from = &b, .to = &a, .dist = 2 },
    Path{ .from = &b, .to = &d, .dist = 1 },
};

const c_paths = [_]Path{
    Path{ .from = &c, .to = &d, .dist = 3 },
    Path{ .from = &c, .to = &e, .dist = 2 },
};

const d_paths = [_]Path{
    Path{ .from = &d, .to = &b, .dist = 1 },
    Path{ .from = &d, .to = &c, .dist = 3 },
    Path{ .from = &d, .to = &f, .dist = 7 },
};

const e_paths = [_]Path{
    Path{ .from = &e, .to = &c, .dist = 2 },
    Path{ .from = &e, .to = &f, .dist = 1 },
};

const f_paths = [_]Path{
    Path{ .from = &f, .to = &d, .dist = 7 },
};

const TripItem = union(enum) {
    place: *const Place,
    path: *const Path,

    fn printMe(self: TripItem) void {
        switch (self) {
            .place => |p| print("{s}", .{p.name}),
            .path => |p| print("--{}->", .{p.dist}),
        }
    }
};

const NotebookEntry = struct {
    place: *const Place,
    coming_from: ?*const Place,
    via_path: ?*const Path,
    dist_to_reach: u16,
};

const HermitsNotebook = struct {
    entries: [place_count]?NotebookEntry = .{null} ** place_count,
    next_entry: u8 = 0,
    end_of_entries: u8 = 0,

    // TODO LOOPS SOLUTION 1
    // fn getEntry(self: *HermitsNotebook, place: *const Place) ?*NotebookEntry {
    //     for (&self.entries, 0..) |*entry, i| {
    //         if (i >= self.end_of_entries) break;
    //         if (place == entry.*.?.place) return &entry.*.?;
    //     }
    //     return null;
    // }

    // TODO LOOPS SOLUTION 2
    fn getEntry(self: *HermitsNotebook, place: *const Place) ?*NotebookEntry {
        var i: usize = 0;
        while (i < self.end_of_entries) {
            const entry = &self.entries[i];
            if (entry.*.?.place == place) {
                return &entry.*.?;
            }
            i += 1;
        }
        return null;
    }

    // TODO LOOPS SOLUTION 3
    // fn getEntry(self: *HermitsNotebook, place: *const Place) ?*NotebookEntry {
    //     for (self.entries[0..self.end_of_entries]) |*entry| {
    //         if (place == entry.*.?.place) return &entry.*.?;
    //     }
    //     return null;
    // }


    fn checkNote(self: *HermitsNotebook, note: NotebookEntry) void {
        const existing_entry = self.getEntry(note.place);

        if (existing_entry == null) {
            self.entries[self.end_of_entries] = note;
            self.end_of_entries += 1;
        } else if (note.dist_to_reach < existing_entry.?.dist_to_reach) {
            existing_entry.?.* = note;
        }
    }

    fn hasNextEntry(self: *HermitsNotebook) bool {
        return self.next_entry < self.end_of_entries;
    }

    fn getNextEntry(self: *HermitsNotebook) *const NotebookEntry {
        defer self.next_entry += 1;
        return &self.entries[self.next_entry].?;
    }

    fn getTripTo(self: *HermitsNotebook, trip: []?TripItem, dest: *Place) !void {
        const destination_entry = self.getEntry(dest);
        if (destination_entry == null) {
            return TripError.Unreachable;
        }

        var current_entry = destination_entry.?;
        var i: u8 = 0;

        while (true) : (i += 2) {
            trip[i] = TripItem{ .place = current_entry.place };

            if (current_entry.coming_from == null) break;

            trip[i + 1] = TripItem{ .path = current_entry.via_path.? };

            const previous_entry = self.getEntry(current_entry.coming_from.?);
            if (previous_entry == null) return TripError.EatenByAGrue;
            current_entry = previous_entry.?;
        }
    }
};

pub fn main() void {
    const start = &a;
    const destination = &f;

    a.paths = a_paths[0..];
    b.paths = b_paths[0..];
    c.paths = c_paths[0..];
    d.paths = d_paths[0..];
    e.paths = e_paths[0..];
    f.paths = f_paths[0..];

    var notebook = HermitsNotebook{};
    var working_note = NotebookEntry{
        .place = start,
        .coming_from = null,
        .via_path = null,
        .dist_to_reach = 0,
    };
    notebook.checkNote(working_note);

    while (notebook.hasNextEntry()) {
        const place_entry = notebook.getNextEntry();

        for (place_entry.place.paths) |*path| {
            working_note = NotebookEntry{
                .place = path.to,
                .coming_from = place_entry.place,
                .via_path = path,
                .dist_to_reach = place_entry.dist_to_reach + path.dist,
            };
            notebook.checkNote(working_note);
        }
    }

    var trip = [_]?TripItem{null} ** (place_count * 2);

    notebook.getTripTo(trip[0..], destination) catch |err| {
        print("Oh no! {}\n", .{err});
        return;
    };

    printTrip(trip[0..]);
}

fn printTrip(trip: []?TripItem) void {
    var i: u8 = @intCast(trip.len);

    while (i > 0) {
        i -= 1;
        if (trip[i] == null) continue;
        trip[i].?.printMe();
    }

    print("\n", .{});
}