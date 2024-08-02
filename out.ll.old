; ModuleID = 'out.bc'
source_filename = "main"

%Foo_methodTable = type <{ ptr }>
%Foo = type { i32, ptr }

@Foo_methodTable = global %Foo_methodTable <{ ptr @Foo_add }>

define i32 @main() local_unnamed_addr {
entry:
  %foo = alloca %Foo, align 8
  store i32 123, ptr %foo, align 8
  %.fca.1.gep = getelementptr inbounds { i32, ptr }, ptr %foo, i64 0, i32 1
  store ptr @Foo_methodTable, ptr %.fca.1.gep, align 8
  %Foo_add = load ptr, ptr @Foo_methodTable, align 8
  %Foo_add1 = call i32 %Foo_add(ptr nonnull %foo)
  ret i32 %Foo_add1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read)
define i32 @Foo_add(ptr nocapture readonly %0) #0 {
entry:
  %loaded_get_age = load i32, ptr %0, align 4
  %addtmp = add i32 %loaded_get_age, 4
  ret i32 %addtmp
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) }
