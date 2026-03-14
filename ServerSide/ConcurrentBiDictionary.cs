using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ServerSide
{
    public class ConcurrentBiDictionary<TKey, TValue> : IEnumerable<KeyValuePair<TKey, TValue>> where TKey : notnull where TValue : notnull
    {
        private readonly ConcurrentDictionary<TKey, TValue> _forward = [];
        private readonly ConcurrentDictionary<TValue, TKey> _reverse = [];
        private readonly object _lock = new();

        public bool TryAdd(TKey key, TValue value) 
        {
            lock (_lock)
            {
                if (_forward.ContainsKey(key) || _reverse.ContainsKey(value)) return false;

                _forward[key] = value;
                _reverse[value] = key;

                return true;
            }
        }

        public bool RemoveByKey(TKey key)
        {
            lock (_lock) 
            {
                if (!_forward.TryRemove(key, out var value)) return false;

                _reverse.TryRemove(value, out _);

                return true;
            }
        }

        public bool RemoveByValue(TValue value)
        {
            lock (_lock)
            {
                if (!_reverse.TryRemove(value, out var key)) return false;

                _forward.TryRemove(key, out _);

                return true;
            }
        }

        public bool TryGetValue(TKey key, out TValue value) => _forward.TryGetValue(key, out value!);

        public bool TryGetKey(TValue value, out TKey key) => _reverse.TryGetValue(value, out key!);

        public TValue this[TKey key] => _forward[key];
        public TKey this[TValue value] => _reverse[value];

        public IEnumerator<KeyValuePair<TKey, TValue>> GetEnumerator() => _forward.GetEnumerator();
        IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
    }
}
