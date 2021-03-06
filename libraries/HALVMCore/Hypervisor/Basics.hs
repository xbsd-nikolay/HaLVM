{-# OPTIONS -fglasgow-exts #-}
-- BANNERSTART
-- - Copyright 2006-2008, Galois, Inc.
-- - This software is distributed under a standard, three-clause BSD license.
-- - Please see the file LICENSE, distributed with this software, for specific
-- - terms and conditions.
-- Author: Andrew Tolmach <apt@galois.com>
-- BANNEREND
-- |Basic constants and definitions for the HALVM and Xen.
module Hypervisor.Basics(
         Err(..)
       , Xen
       , DomId(..)
       , SID(..)
       , VCPU(..)
       , domidSelf
       , ignoreErrors
       , xThrow
       , xOnException
       , xCatch
       , xTry
       )
where

--import Control.Monad.Error.Class
import Control.Exception
import Data.Word
import Data.Generics(Data, Typeable)
import Foreign.Storable(Storable)
import Prelude hiding (catch)

-- |A type for running Xen hypercall, or near-hypercall, functions and
-- returning the result or error.
type Xen a = IO a

-- |Run the given Xen computation. If it completes successfully, return the
-- result. Otherwise, fail. This is in contrast to the usual case, where you
-- would be able to see and inspect the error value.
ignoreErrors :: Xen a -> Xen a
ignoreErrors action = catch action ignoreXenErr

ignoreXenErr :: Err -> Xen a
ignoreXenErr e = fail $ "Error while running ignoreErrors: " ++ show e

xThrow :: Err -> Xen a
xThrow e = throwIO e

xOnException :: Xen a -> Xen b -> Xen a
xOnException xen patchUp = xen `xCatch` (\e -> patchUp >> xThrow e)

xCatch :: Xen a -> (Err -> Xen a) -> Xen a
xCatch  = catch

xTry :: Xen a -> Xen (Either Err a)
xTry m = (m >>= (return . Right)) `xCatch` (return . Left)

-- |Error codes returned from hypervisor calls. 
-- Xen takes this directly from linux  @\/usr\/include\/asm\/errno.h@).
-- Only a small subset of these codes are actually used by xen (but there
-- is no documentation as to which ones these are).
data Err = 
      EOK      -- ^ (not used; just to get enum aligned right)
	| EPERM		 	-- ^ Operation not permitted 
	| ENOENT		-- ^ No such file or directory 
	| ESRCH		 	-- ^ No such process 
	| EINTR		 	-- ^ Interrupted system call 
	| EIO		 	-- ^ IO error 
	| ENXIO		 	-- ^ No such device or address 
	| E2BIG		 	-- ^ Argument list too long 
	| ENOEXEC		-- ^ Exec format error 
	| EBADF			-- ^ Bad file number 
	| ECHILD		-- ^ No child processes 
	| EAGAIN		-- ^ Try again 
	| ENOMEM		-- ^ Out of memory 
	| EACCES		-- ^ Permission denied 
	| EFAULT		-- ^ Bad address 
	| ENOTBLK		-- ^ Block device required 
	| EBUSY			-- ^ Device or resource busy 
	| EEXIST		-- ^ File exists 
	| EXDEV			-- ^ Cross-device link 
	| ENODEV		-- ^ No such device 
	| ENOTDIR		-- ^ Not a directory 
	| EISDIR		-- ^ Is a directory 
	| EINVAL		-- ^ Invalid argument 
	| ENFILE		-- ^ File table overflow 
	| EMFILE		-- ^ Too many open files 
	| ENOTTY		-- ^ Not a typewriter 
	| ETXTBSY		-- ^ Text file busy 
	| EFBIG			-- ^ File too large 
	| ENOSPC		-- ^ No space left on device 
	| ESPIPE		-- ^ Illegal seek 
	| EROFS			-- ^ Read-only file system 
	| EMLINK		-- ^ Too many links 
	| EPIPE			-- ^ Broken pipe 
	| EDOM			-- ^ Math argument out of domain of func 
	| ERANGE		-- ^ Math result not representable 
	| EDEADLK		-- ^ Resource deadlock would occur 
	| ENAMETOOLONG		-- ^ File name too long 
	| ENOLCK		-- ^ No record locks available 
	| ENOSYS		-- ^ Function not implemented 
	| ENOTEMPTY		-- ^ Directory not empty 
	| ELOOP			-- ^ Too many symbolic links encountered 
	| EWOULDBLOCK		-- ^ Operation would block (not used; try EAGAIN)
	| ENOMSG		-- ^ No message of desired type 
	| EIDRM			-- ^ Identifier removed 
	| ECHRNG		-- ^ Channel number out of range 
	| EL2NSYNC		-- ^ Level 2 not synchronized 
	| EL3HLT		-- ^ Level 3 halted 
	| EL3RST		-- ^ Level 3 reset 
	| ELNRNG		-- ^ Link number out of range 
	| EUNATCH		-- ^ Protocol driver not attached 
	| ENOCSI		-- ^ No CSI structure available 
	| EL2HLT		-- ^ Level 2 halted 
	| EBADE			-- ^ Invalid exchange 
	| EBADR			-- ^ Invalid request descriptor 
	| EXFULL		-- ^ Exchange full 
	| ENOANO		-- ^ No anode 
	| EBADRQC		-- ^ Invalid request code 
	| EBADSLT		-- ^ Invalid slot 
    | EDEADLOCK             -- ^ (Not used: try EDEADLK)
	| EBFONT		-- ^ Bad font file format 
	| ENOSTR		-- ^ Device not a stream 
	| ENODATA		-- ^ No data available 
	| ETIME			-- ^ Timer expired 
	| ENOSR			-- ^ Out of streams resources 
	| ENONET		-- ^ Machine is not on the network 
	| ENOPKG		-- ^ Package not installed 
	| EREMOTE		-- ^ Object is remote 
	| ENOLINK		-- ^ Link has been severed 
	| EADV			-- ^ Advertise error 
	| ESRMNT		-- ^ Srmount error 
	| ECOMM			-- ^ Communication error on send 
	| EPROTO		-- ^ Protocol error 
	| EMULTIHOP		-- ^ Multihop attempted 
	| EDOTDOT		-- ^ RFS specific error 
	| EBADMSG		-- ^ Not a data message 
	| EOVERFLOW		-- ^ Value too large for defined data type 
	| ENOTUNIQ		-- ^ Name not unique on network 
	| EBADFD		-- ^ File descriptor in bad state 
	| EREMCHG		-- ^ Remote address changed 
	| ELIBACC		-- ^ Can not access a needed shared library 
	| ELIBBAD		-- ^ Accessing a corrupted shared library 
	| ELIBSCN		-- ^ .lib section in a.out corrupted 
	| ELIBMAX		-- ^ Attempting to link in too many shared libraries 
	| ELIBEXEC		-- ^ Cannot exec a shared library directly 
	| EILSEQ		-- ^ Illegal byte sequence 
	| ERESTART		-- ^ Interrupted system call should be restarted 
	| ESTRPIPE		-- ^ Streams pipe error 
	| EUSERS		-- ^ Too many users 
	| ENOTSOCK		-- ^ Socket operation on non-socket 
	| EDESTADDRREQ		-- ^ Destination address required 
	| EMSGSIZE		-- ^ Message too long 
	| EPROTOTYPE		-- ^ Protocol wrong type for socket 
	| ENOPROTOOPT		-- ^ Protocol not available 
	| EPROTONOSUPPORT	-- ^ Protocol not supported 
	| ESOCKTNOSUPPORT	-- ^ Socket type not supported 
	| EOPNOTSUPP		-- ^ Operation not supported on transport endpoint 
	| EPFNOSUPPORT		-- ^ Protocol family not supported 
	| EAFNOSUPPORT		-- ^ Address family not supported by protocol 
	| EADDRINUSE		-- ^ Address already in use 
	| EADDRNOTAVAIL		-- ^ Cannot assign requested address 
	| ENETDOWN		-- ^ Network is down 
	| ENETUNREACH		-- ^ Network is unreachable 
	| ENETRESET		-- ^ Network dropped connection because of reset 
	| ECONNABORTED		-- ^ Software caused connection abort 
	| ECONNRESET		-- ^ Connection reset by peer 
	| ENOBUFS		-- ^ No buffer space available 
	| EISCONN		-- ^ Transport endpoint is already connected 
	| ENOTCONN		-- ^ Transport endpoint is not connected 
	| ESHUTDOWN		-- ^ Cannot send after transport endpoint shutdown 
	| ETOOMANYREFS		-- ^ Too many references: cannot splice 
	| ETIMEDOUT		-- ^ Connection timed out 
	| ECONNREFUSED		-- ^ Connection refused 
	| EHOSTDOWN		-- ^ Host is down 
	| EHOSTUNREACH		-- ^ No route to host 
	| EALREADY		-- ^ Operation already in progress 
	| EINPROGRESS		-- ^ Operation now in progress 
	| ESTALE		-- ^ Stale NFS file handle 
	| EUCLEAN		-- ^ Structure needs cleaning 
	| ENOTNAM		-- ^ Not a XENIX named type file 
	| ENAVAIL		-- ^ No XENIX semaphores available 
	| EISNAM		-- ^ Is a named type file 
	| EREMOTEIO		-- ^ Remote IO error 
	| EDQUOT		-- ^ Quota exceeded 
	| ENOMEDIUM		-- ^ No medium found 
	| EMEDIUMTYPE		-- ^ Wrong medium type
 deriving (Show,Read,Enum,Eq,Typeable)

instance Exception Err


-- |The generic "self" domain ID defined by Xen. Note that you should only use
-- this value when interacting with Xen; passing it to another domain will not
-- work well.  For that purpose, consider 'Hypervisor.Privileged.myDomId'.
domidSelf :: DomId
domidSelf = DomId 0x7FF0

-- | Virtual CPU number (0 always exists)
newtype VCPU = VCPU Word32
   deriving (Eq,Ord,Show {- ,Storable -})

-- | Xen Domain identifiers 
newtype DomId = DomId Word16
    deriving (Eq,Ord,Show,Read, Typeable, Data,Storable)

-- | Security Identifiers
newtype SID = SID Word32
    deriving (Eq,Ord,Show,Read, Typeable, Data,Storable)

