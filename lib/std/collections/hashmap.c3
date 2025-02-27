// Copyright (c) 2023 Christoffer Lerno. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.
<*
 @require $defined((Key){}.hash()) `No .hash function found on the key`
*>
module std::collections::map(<Key, Value>);
import std::math;
import std::io @norecurse;

struct HashMap (Printable)
{
	Entry*[] table;
	Allocator allocator;
	uint count; // Number of elements
	uint threshold; // Resize limit
	float load_factor;
}

<*
 @param [&inout] allocator "The allocator to use"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.new_init(&self, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR, Allocator allocator = null) @deprecated("Use init(mem)")
{
	return self.init(allocator ?: allocator::heap(), capacity, load_factor);
}

<*
 @param [&inout] allocator "The allocator to use"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.init(&self, Allocator allocator, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR)
{
	capacity = math::next_power_of_2(capacity);
	self.allocator = allocator;
	self.load_factor = load_factor;
	self.threshold = (uint)(capacity * load_factor);
	self.table = allocator::new_array(allocator, Entry*, capacity);
	return self;
}

<*
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.temp_init(&self, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR) @deprecated("Use tinit()")
{
	return self.init(allocator::temp(), capacity, load_factor) @inline;
}

<*
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.tinit(&self, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR)
{
	return self.init(allocator::temp(), capacity, load_factor) @inline;
}

<*
 @param [&inout] allocator "The allocator to use"
 @require $vacount % 2 == 0 "There must be an even number of arguments provided for keys and values"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
macro HashMap* HashMap.new_init_with_key_values(&self, ..., uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR, Allocator allocator = allocator::heap()) @deprecated("Use init_with_key_values(mem)")
{
	self.init(capacity, load_factor, allocator);
	$for (var $i = 0; $i < $vacount; $i += 2)
		self.set($vaarg[$i], $vaarg[$i+1]);
	$endfor
	return self;
}

<*
 @param [in] keys "The keys for the HashMap entries"
 @param [in] values "The values for the HashMap entries"
 @param [&inout] allocator "The allocator to use"
 @require keys.len == values.len "Both keys and values arrays must be the same length"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.new_init_from_keys_and_values(&self, Key[] keys, Value[] values, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR, Allocator allocator = allocator::heap()) @deprecated("Use init_from_keys_and_values(mem)")
{
	assert(keys.len == values.len);
	self.init(allocator, capacity, load_factor);
	for (usz i = 0; i < keys.len; i++)
	{
		self.set(keys[i], values[i]);
	}
	return self;
}

<*
 @require $vacount % 2 == 0 "There must be an even number of arguments provided for keys and values"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
macro HashMap* HashMap.temp_init_with_key_values(&self, ..., uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR) @deprecated("Use tinit_with_key_values")
{
	self.tinit(capacity, load_factor);
	$for (var $i = 0; $i < $vacount; $i += 2)
		self.set($vaarg[$i], $vaarg[$i+1]);
	$endfor
	return self;
}

<*
 @require $vacount % 2 == 0 "There must be an even number of arguments provided for keys and values"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
macro HashMap* HashMap.tinit_with_key_values(&self, ..., uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR)
{
	self.tinit(capacity, load_factor);
	$for (var $i = 0; $i < $vacount; $i += 2)
		self.set($vaarg[$i], $vaarg[$i+1]);
	$endfor
	return self;
}

<*
 @param [in] keys "The keys for the HashMap entries"
 @param [in] values "The values for the HashMap entries"
 @param [&inout] allocator "The allocator to use"
 @require keys.len == values.len "Both keys and values arrays must be the same length"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.temp_init_from_keys_and_values(&self, Key[] keys, Value[] values, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR, Allocator allocator = allocator::heap()) @deprecated("Use tinit_from_keys_and_values")
{
	assert(keys.len == values.len);
	self.tinit(capacity, load_factor);
	for (usz i = 0; i < keys.len; i++)
	{
		self.set(keys[i], values[i]);
	}
	return self;
}

<*
 @param [in] keys "The keys for the HashMap entries"
 @param [in] values "The values for the HashMap entries"
 @param [&inout] allocator "The allocator to use"
 @require keys.len == values.len "Both keys and values arrays must be the same length"
 @require capacity > 0 "The capacity must be 1 or higher"
 @require load_factor > 0.0 "The load factor must be higher than 0"
 @require !self.allocator "Map was already initialized"
 @require capacity < MAXIMUM_CAPACITY "Capacity cannot exceed maximum"
*>
fn HashMap* HashMap.tinit_from_keys_and_values(&self, Key[] keys, Value[] values, uint capacity = DEFAULT_INITIAL_CAPACITY, float load_factor = DEFAULT_LOAD_FACTOR, Allocator allocator = allocator::heap())
{
	assert(keys.len == values.len);
	self.tinit(capacity, load_factor);
	for (usz i = 0; i < keys.len; i++)
	{
		self.set(keys[i], values[i]);
	}
	return self;
}

<*
 Has this hash map been initialized yet?

 @param [&in] map "The hash map we are testing"
 @return "Returns true if it has been initialized, false otherwise"
*>
fn bool HashMap.is_initialized(&map)
{
	return (bool)map.allocator;
}

<*
 @param [&in] other_map "The map to copy from."
*>
fn HashMap* HashMap.new_init_from_map(&self, HashMap* other_map) @deprecated("Use init_from_map(mem, map)")
{
	return self.init_from_map(allocator::heap(), other_map) @inline;
}

<*
 @param [&inout] allocator "The allocator to use"
 @param [&in] other_map "The map to copy from."
*>
fn HashMap* HashMap.init_from_map(&self, Allocator allocator, HashMap* other_map)
{
	self.init(allocator, other_map.table.len, other_map.load_factor);
	self.put_all_for_create(other_map);
	return self;
}

<*
 @param [&in] other_map "The map to copy from."
*>
fn HashMap* HashMap.temp_init_from_map(&map, HashMap* other_map) @deprecated("Use tinit_from_map")
{
	return map.init_from_map(allocator::temp(), other_map) @inline;
}

<*
 @param [&in] other_map "The map to copy from."
*>
fn HashMap* HashMap.tinit_from_map(&map, HashMap* other_map)
{
	return map.init_from_map(allocator::temp(), other_map) @inline;
}

fn bool HashMap.is_empty(&map) @inline
{
	return !map.count;
}

fn usz HashMap.len(&map) @inline
{
	return map.count;
}

fn Value*! HashMap.get_ref(&map, Key key)
{
	if (!map.count) return SearchResult.MISSING?;
	uint hash = rehash(key.hash());
	for (Entry *e = map.table[index_for(hash, map.table.len)]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(key, e.key)) return &e.value;
	}
	return SearchResult.MISSING?;
}

fn Entry*! HashMap.get_entry(&map, Key key)
{
	if (!map.count) return SearchResult.MISSING?;
	uint hash = rehash(key.hash());
	for (Entry *e = map.table[index_for(hash, map.table.len)]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(key, e.key)) return e;
	}
	return SearchResult.MISSING?;
}

<*
 Get the value or update and
 @require $assignable(#expr, Value)
*>
macro Value HashMap.@get_or_set(&map, Key key, Value #expr)
{
	if (!map.count)
	{
		Value val = #expr;
		map.set(key, val);
		return val;
	}
	uint hash = rehash(key.hash());
	uint index = index_for(hash, map.table.len);
	for (Entry *e = map.table[index]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(key, e.key)) return e.value;
	}
	Value val = #expr;
	map.add_entry(hash, key, val, index);
	return val;
}

fn Value! HashMap.get(&map, Key key) @operator([])
{
	return *map.get_ref(key) @inline;
}

fn bool HashMap.has_key(&map, Key key)
{
	return @ok(map.get_ref(key));
}

fn bool HashMap.set(&map, Key key, Value value) @operator([]=)
{
	// If the map isn't initialized, use the defaults to initialize it.
	if (!map.allocator)
	{
		map.init(allocator::heap());
	}
	uint hash = rehash(key.hash());
	uint index = index_for(hash, map.table.len);
	for (Entry *e = map.table[index]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(key, e.key))
		{
			e.value = value;
			return true;
		}
	}
	map.add_entry(hash, key, value, index);
	return false;
}

fn void! HashMap.remove(&map, Key key) @maydiscard
{
	if (!map.remove_entry_for_key(key)) return SearchResult.MISSING?;
}

fn void HashMap.clear(&map)
{
	if (!map.count) return;
	foreach (Entry** &entry_ref : map.table)
	{
		Entry* entry = *entry_ref;
		if (!entry) continue;
		Entry *next = entry.next;
		while (next)
		{
			Entry *to_delete = next;
			next = next.next;
			map.free_entry(to_delete);
		}
		map.free_entry(entry);
		*entry_ref = null;
	}
	map.count = 0;
}

fn void HashMap.free(&map)
{
	if (!map.allocator) return;
	map.clear();
	map.free_internal(map.table.ptr);
	map.table = {};
}

fn Key[] HashMap.tcopy_keys(&map)
{
	return map.copy_keys(allocator::temp()) @inline;
}

fn Key[] HashMap.key_tlist(&map) @deprecated("Use 'tcopy_keys'")
{
	return map.copy_keys(allocator::temp()) @inline;
}

<*
 @deprecated "use copy_keys"
*>
fn Key[] HashMap.key_new_list(&map, Allocator allocator = allocator::heap())
{
	return map.copy_keys(allocator) @inline;
}

fn Key[] HashMap.copy_keys(&map, Allocator allocator = allocator::heap())
{
	if (!map.count) return {};

	Key[] list = allocator::alloc_array(allocator, Key, map.count);
	usz index = 0;
	foreach (Entry* entry : map.table)
	{
		while (entry)
		{
			$if COPY_KEYS:
				list[index++] = entry.key.copy(allocator);
			$else
				list[index++] = entry.key;
			$endif
			entry = entry.next;
		}
	}
	return list;
}

macro HashMap.@each(map; @body(key, value))
{
	map.@each_entry(; Entry* entry) {
		@body(entry.key, entry.value);
	};
}

macro HashMap.@each_entry(map; @body(entry))
{
	if (map.count)
	{
		foreach (Entry* entry : map.table)
		{
			while (entry)
			{
				@body(entry);
				entry = entry.next;
			}
		}
	}
}

<*
 @deprecated `use tcopy_values`
*>
fn Value[] HashMap.value_tlist(&map)
{
	return map.copy_values(allocator::temp()) @inline;
}

fn Value[] HashMap.tcopy_values(&map)
{
	return map.copy_values(allocator::temp()) @inline;
}

<*
 @deprecated `use copy_values`
*>
fn Value[] HashMap.value_new_list(&map, Allocator allocator = allocator::heap())
{
	return map.copy_values(allocator);
}

fn Value[] HashMap.copy_values(&map, Allocator allocator = allocator::heap())
{
	if (!map.count) return {};
	Value[] list = allocator::alloc_array(allocator, Value, map.count);
	usz index = 0;
	foreach (Entry* entry : map.table)
	{
		while (entry)
		{
			list[index++] = entry.value;
			entry = entry.next;
		}
	}
	return list;
}

fn bool HashMap.has_value(&map, Value v) @if(VALUE_IS_EQUATABLE)
{
	if (!map.count) return false;
	foreach (Entry* entry : map.table)
	{
		while (entry)
		{
			if (equals(v, entry.value)) return true;
			entry = entry.next;
		}
	}
	return false;
}

fn HashMapIterator HashMap.iter(&self)
{
	return { .map = self, .index = -1 };
}

fn HashMapValueIterator HashMap.value_iter(&self)
{
	return { .map = self, .index = -1 };
}

fn HashMapKeyIterator HashMap.key_iter(&self)
{
	return { .map = self, .index = -1 };
}

// --- private methods

fn void HashMap.add_entry(&map, uint hash, Key key, Value value, uint bucket_index) @private
{
	$if COPY_KEYS:
	key = key.copy(map.allocator);
	$endif
	Entry* entry = allocator::new(map.allocator, Entry, { .hash = hash, .key = key, .value = value, .next = map.table[bucket_index] });
	map.table[bucket_index] = entry;
	if (map.count++ >= map.threshold)
	{
		map.resize(map.table.len * 2);
	}
}

fn void HashMap.resize(&map, uint new_capacity) @private
{
	Entry*[] old_table = map.table;
	uint old_capacity = old_table.len;
	if (old_capacity == MAXIMUM_CAPACITY)
	{
		map.threshold = uint.max;
		return;
	}
	Entry*[] new_table = allocator::new_array(map.allocator, Entry*, new_capacity);
	map.transfer(new_table);
	map.table = new_table;
	map.free_internal(old_table.ptr);
	map.threshold = (uint)(new_capacity * map.load_factor);
}

fn usz! HashMap.to_format(&self, Formatter* f) @dynamic
{
	usz len;
	len += f.print("{ ")!;
	self.@each_entry(; Entry* entry)
	{
		if (len > 2) len += f.print(", ")!;
		len += f.printf("%s: %s", entry.key, entry.value)!;
    };
	return len + f.print(" }");
}

fn void HashMap.transfer(&map, Entry*[] new_table) @private
{
	Entry*[] src = map.table;
	uint new_capacity = new_table.len;
	foreach (uint j, Entry *e : src)
	{
		if (!e) continue;
		do
		{
			Entry* next = e.next;
			uint i = index_for(e.hash, new_capacity);
			e.next = new_table[i];
			new_table[i] = e;
			e = next;
		}
		while (e);
	}
}

fn void HashMap.put_all_for_create(&map, HashMap* other_map) @private
{
	if (!other_map.count) return;
	foreach (Entry *e : other_map.table)
	{
		while (e)
		{
			map.put_for_create(e.key, e.value);
			e = e.next;
		}
	}
}

fn void HashMap.put_for_create(&map, Key key, Value value) @private
{
	uint hash = rehash(key.hash());
	uint i = index_for(hash, map.table.len);
	for (Entry *e = map.table[i]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(key, e.key))
		{
			e.value = value;
			return;
		}
	}
	map.create_entry(hash, key, value, i);
}

fn void HashMap.free_internal(&map, void* ptr) @inline @private
{
	allocator::free(map.allocator, ptr);
}

fn bool HashMap.remove_entry_for_key(&map, Key key) @private
{
	if (!map.count) return false;
	uint hash = rehash(key.hash());
	uint i = index_for(hash, map.table.len);
	Entry* prev = map.table[i];
	Entry* e = prev;
	while (e)
	{
		Entry *next = e.next;
		if (e.hash == hash && equals(key, e.key))
		{
			map.count--;
			if (prev == e)
			{
				map.table[i] = next;
			}
			else
			{
				prev.next = next;
			}
			map.free_entry(e);
			return true;
		}
		prev = e;
		e = next;
	}
	return false;
}

fn void HashMap.create_entry(&map, uint hash, Key key, Value value, int bucket_index) @private
{
	Entry *e = map.table[bucket_index];
	$if COPY_KEYS:
	key = key.copy(map.allocator);
	$endif
	Entry* entry = allocator::new(map.allocator, Entry, { .hash = hash, .key = key, .value = value, .next = map.table[bucket_index] });
	map.table[bucket_index] = entry;
	map.count++;
}

fn void HashMap.free_entry(&self, Entry *entry) @local
{
	$if COPY_KEYS:
	allocator::free(self.allocator, entry.key);
	$endif
	self.free_internal(entry);
}


struct HashMapIterator
{
	HashMap* map;
	int top_index;
	int index;
	Entry* current_entry;
}

distinct HashMapValueIterator = HashMapIterator;
distinct HashMapKeyIterator = HashMapIterator;


<*
 @require idx < self.map.count
*>
fn Entry HashMapIterator.get(&self, usz idx) @operator([])
{
	if (idx < self.index)
	{
		self.top_index = 0;
		self.current_entry = null;
		self.index = -1;
	}
	while (self.index != idx)
	{
		if (self.current_entry)
		{
			self.current_entry = self.current_entry.next;
			if (self.current_entry) self.index++;
			continue;
		}
		self.current_entry = self.map.table[self.top_index++];
		if (self.current_entry) self.index++;
	}
	return *self.current_entry;
}

fn Value HashMapValueIterator.get(&self, usz idx) @operator([])
{
	return ((HashMapIterator*)self).get(idx).value;
}

fn Key HashMapKeyIterator.get(&self, usz idx) @operator([])
{
	return ((HashMapIterator*)self).get(idx).key;
}

fn usz HashMapValueIterator.len(self) @operator(len) => self.map.count;
fn usz HashMapKeyIterator.len(self) @operator(len) => self.map.count;
fn usz HashMapIterator.len(self) @operator(len) => self.map.count;
