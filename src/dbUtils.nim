import std/times
import tiny_sqlite

proc toDbValue*(t: DateTime): DbValue {.raises: [].} =
    DbValue(kind: sqliteText, strVal: $t)

proc fromDbValue*(value: DbValue, T: typedesc[DateTime]): DateTime {.raises: [].} =
    try:
        case value.kind:
            of sqliteText: return times.parse(value.strVal, "yyyy-MM-dd'T'HH:mm:sszzz")
            else: return
    except TimeParseError:
        return
