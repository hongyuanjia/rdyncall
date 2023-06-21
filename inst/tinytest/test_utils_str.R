# TODO: ptr2str(as.externalptr("")) crashes R
expect_true(is.externalptr(strptr("")))
expect_equal(ptr2str(strptr("")), "")
expect_true(is.externalptr(strarrayptr(LETTERS)))
