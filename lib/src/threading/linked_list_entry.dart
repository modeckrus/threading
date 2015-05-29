part of threading;

class _LinkedListEntry<E> extends LinkedListEntry<_LinkedListEntry<E>> {
  E element;

  _LinkedListEntry(this.element);
}
