module type Scanner_type = sig
  val input : string
end

module Make : functor (_ : Scanner_type) -> sig
  val scan : unit -> Token.t list
end

exception Scanner_error of string
