(*
copyright (c) 2013-2014, simon cruanes
all rights reserved.

redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 Array utils} *)

type 'a sequence = ('a -> unit) -> unit
type 'a klist = unit -> [`Nil | `Cons of 'a * 'a klist]
type 'a gen = unit -> 'a option
type 'a equal = 'a -> 'a -> bool
type 'a ord = 'a -> 'a -> int

(** {2 Abstract Signature} *)

module type S = sig
  type 'a t
  (** Array, or sub-array, containing elements of type ['a] *)

  val empty : 'a t

  val equal : 'a equal -> 'a t equal

  val compare : 'a ord -> 'a t ord

  val get : 'a t -> int -> 'a

  val set : 'a t -> int -> 'a -> unit

  val length : _ t -> int

  val fold : ('b -> 'a -> 'b) -> 'b -> 'a t -> 'b

  val foldi : ('b -> int -> 'a -> 'b) -> 'b -> 'a t -> 'b
  (** fold left on array, with index *)

  val iter : ('a -> unit) -> 'a t -> unit

  val iteri : (int -> 'a -> unit) -> 'a t -> unit

  val reverse_in_place : 'a t -> unit
  (** Reverse the array in place *)

  val find : ('a -> 'b option) -> 'a t -> 'b option
  (** [find f a] returns [Some y] if there is an element [x] such
      that [f x = Some y], else it returns [None] *)

  val for_all : ('a -> bool) -> 'a t -> bool

  val for_all2 : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
  (** Forall on pairs of arrays.
      @raise Invalid_argument if they have distinct lengths *)

  val exists : ('a -> bool) -> 'a t -> bool

  val exists2 : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
  (** Exists on pairs of arrays.
      @raise Invalid_argument if they have distinct lengths *)

  val shuffle : 'a t -> unit
  (** shuffle randomly the array, in place *)

  val shuffle_with : Random.State.t -> 'a t -> unit
  (** Like shuffle but using a specialized random state *)

  val to_seq : 'a t -> 'a sequence
  val to_gen : 'a t -> 'a gen
  val to_klist : 'a t -> 'a klist

  (** {2 IO} *)

  val pp: ?sep:string -> (Buffer.t -> 'a -> unit)
            -> Buffer.t -> 'a t -> unit
  (** print an array of items with printing function *)

  val pp_i: ?sep:string -> (Buffer.t -> int -> 'a -> unit)
            -> Buffer.t -> 'a t -> unit
  (** print an array, giving the printing function both index and item *)

  val print : ?sep:string -> (Format.formatter -> 'a -> unit)
            -> Format.formatter -> 'a t -> unit
  (** print an array of items with printing function *)
end

(** {2 Arrays} *)

type 'a t = 'a array

include S with type 'a t := 'a t

val map : ('a -> 'b) -> 'a t -> 'b t

val filter : ('a -> bool) -> 'a t -> 'a t
(** Filter elements out of the array. Only the elements satisfying
    the given predicate will be kept. *)

val filter_map : ('a -> 'b option) -> 'a t -> 'b t
(** Map each element into another value, or discard it *)

val flat_map : ('a -> 'b t) -> 'a t -> 'b array
(** transform each element into an array, then flatten *)

val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
(** Infix version of {!flat_map} *)

val except_idx : 'a t -> int -> 'a list
(** Remove given index, obtaining the list of the other elements *)

val (--) : int -> int -> int t
(** Range array *)

(** {2 Slices}
A slice is a part of an array, that requires no copying and shares
its storage with the original array.

All indexing in a slice is relative to the beginning of a slice, not
to the underlying array (meaning a slice is effectively like
a regular array) *)

module Sub : sig
  type 'a t
  (** A slice is an array, an offset, and a length *)

  val make : 'a array -> int -> len:int -> 'a t
  (** Create a slice.
      @raise Invalid_argument if the slice isn't valid *)

  val full : 'a array -> 'a t
  (** Slice that covers the full array *)

  val underlying : 'a t -> 'a array
  (** Underlying array (shared). Modifying this array will modify the slice *)
  
  val copy : 'a t -> 'a array
  (** Copy into a new array *)

  val sub : 'a t -> int -> int -> 'a t
  (** Sub-slice *)

  include S with type 'a t := 'a t
end

