; ModuleID = 'main'
source_filename = "main"

%_fn_x_27.closure.type = type { ptr, ptr }

@fmtStr = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @main() {
entry:
  %i = tail call ptr @malloc(i32 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i32))
  store i32 123, ptr %i, align 4
  %_fn_x_27.closure.ptr = tail call ptr @malloc(i32 ptrtoint (ptr getelementptr (%_fn_x_27.closure.type, ptr null, i32 1) to i32))
  %_fn_x_27.gep.ptr = getelementptr inbounds %_fn_x_27.closure.type, ptr %_fn_x_27.closure.ptr, i32 0, i32 0
  store ptr @_fn_x_27, ptr %_fn_x_27.gep.ptr, align 8
  %capture.i.gep = getelementptr inbounds %_fn_x_27.closure.type, ptr %_fn_x_27.closure.ptr, i32 0, i32 1
  store ptr %i, ptr %capture.i.gep, align 8
  %_fn_x_27.fnPtr = getelementptr inbounds %_fn_x_27.closure.type, ptr %_fn_x_27.closure.ptr, i32 0, i32 0
  %_fn_x_27.call = call i32 %_fn_x_27.fnPtr(i32 2, ptr %_fn_x_27.closure.ptr)
  ret i32 %_fn_x_27.call
}

declare i32 @printf(ptr %0, ...)

declare noalias ptr @malloc(i32 %0)

define i32 @_fn_x_27(i32 %x, ptr %0) {
entry:
  %capture.0.gep = getelementptr inbounds %_fn_x_27.closure.type, ptr %0, i32 0, i32 1
  %capture.0.load = load i32, ptr %capture.0.gep, align 4
  %addtmp = add i32 %capture.0.load, %x
  ret i32 %addtmp
}
