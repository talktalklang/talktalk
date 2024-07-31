; ModuleID = 'main'
source_filename = "main"

%Foo = type { i32, ptr }

@fmtStr = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@Foo = external global %Foo
@Foo_methodTable = global [1 x ptr] [ptr @Foo_add]

define i32 @main() {
entry:
  %bar = alloca i32, align 4
  %foo = alloca %Foo, align 8
  store { i32, ptr } { i32 123, ptr @Foo_methodTable }, ptr %foo, align 8
  %vtable_ptr_Foo = getelementptr inbounds %Foo, ptr %foo, i32 0, i32 0
  %gep_Foo_add = getelementptr [1 x ptr], ptr %vtable_ptr_Foo, i32 0
  %Foo_add = load ptr, ptr %gep_Foo_add, align 8
  %Foo_add1 = call i32 %Foo_add(ptr %foo)
  store i32 %Foo_add1, ptr %bar, align 4
  %bar2 = load i32, ptr %bar, align 4
  %printfCall = call i32 (ptr, ...) @printf(ptr @fmtStr, i32 %bar2)
  ret i32 %printfCall
}

declare i32 @printf(ptr %0, ...)

define i32 @Foo_add(ptr %0) {
entry:
  %get_age = getelementptr inbounds %Foo, ptr %0, i32 0, i32 0
  %loaded_get_age = load i32, ptr %get_age, align 4
  %addtmp = add i32 %loaded_get_age, 4
  ret i32 %addtmp
}
