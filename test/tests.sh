#! /bin/zsh

# The tests avoid using wd's internal functions to check the state of
# warp points. We use `--quiet` to prevent the test output being
# flooded by wd's output.


### Variables

# use a test config file, which is removed at the final test teardown.
WD_TEST_CONFIG=~/.warprc_test

# used when testing
WD_TEST_DIR=test_dir
WD_TEST_WP=test

### shUnit setup

# ZSH specific shUnit stuff
setopt shwordsplit
SHUNIT_PARENT=$0

# reset config for each test
setUp()
{
    cat /dev/null > $WD_TEST_CONFIG
}

oneTimeTearDown()
{
    rm -rf $WD_TEST_DIR
    rm $WD_TEST_CONFIG
}

### Helpers

WD_PATH=${PWD}/..

wd()
{
    # run the local wd with the test config
    ${WD_PATH}/wd.sh -d -c $WD_TEST_CONFIG "$@"
}

total_wps()
{
    # total wps is the number of (non-empty) lines in the config
    echo $(cat $WD_TEST_CONFIG | sed '/^\s*$/d' | wc -l)
}

wp_exists()
{
    wd list | grep -q "$1[[:space:]]*->"
    echo $?
}

create_test_wp()
{
    # create test dir
    mkdir $WD_TEST_DIR

    # create test wp
    cd $WD_TEST_DIR
    wd -q add $WD_TEST_WP
    cd ..
}

destroy_test_wp()
{
    rm -rf $WD_TEST_DIR
    wd -q rm $WD_TEST_DIR
}


### Tests

# basic functionality
test_empty_config()
{
    assertEquals "should initially be an empty config" \
        0 $(total_wps)
}

test_simple_add_remove()
{
    wd -q add foo
    assertTrue "should successfully add wp 'foo'" \
        $pipestatus

    assertEquals "should have 1 wps" \
        1 $(total_wps)

    assertTrue "wp 'foo' should exist" \
        $(wp_exists "foo")

    wd -q rm foo
    assertEquals "wps should be empty" \
        0 $(total_wps)
}

test_no_duplicates()
{
    wd -q add foo
    assertTrue "should successfully add 'foo'" \
        $pipestatus

    wd -q add foo
    assertFalse "should fail when adding duplicate of 'foo'" \
        $pipestatus
}


test_valid_identifiers()
{
    wd -q add .
    assertFalse "should not allow only dots" \
        $pipestatus

    wd -q add ..
    assertFalse "should not allow only dots" \
        $pipestatus

    wd -q add hej.
    assertTrue "should allow dots in name" \
        $pipestatus

    wd -q add "foo bar"
    assertFalse "should not allow whitespace" \
        $pipestatus

    wd -q add "foo:bar"
    assertFalse "should not allow colons" \
        $pipestatus

    wd -q add ":foo"
    assertFalse "should not allow colons" \
        $pipestatus

    wd -q add
    assertFalse "should not allow empty name" \
        $pipestatus
}


test_removal()
{
    wd -q add foo

    wd -q rm bar
    assertFalse "should fail when removing non-existing point" \
        $pipestatus

    wd -q rm foo
    assertTrue "should remove existing point" \
        $pipestatus
}


test_list()
{
    wd -q add foo

    # add one to expected number of lines, because of header msg
    assertEquals "should only be one warp point" \
        $(wd list | wc -l) 2

    wd -q add bar

    assertEquals "should be more than one warp point" \
        $(wd list | wc -l) 3
}

test_show()
{
    if [[ ! $(wd show) =~ "No warp point to $(echo $PWD | sed "s:$HOME:~:")" ]]
    then
        fail "should show no warp points"
    fi

    wd -q add foo

    if [[ ! $(wd show) =~ '1 warp point.*foo' ]]
    then
        fail "should show 1 warp point 'foo'"
    fi

    wd -q add bar

    if [[ ! $(wd show) =~ '2 warp point.*foo bar' ]]
    then
        fail "should show 2 warp points 'foo bar'"
    fi

    # test with optional name argument
    if [[ ! $(wd show foo) =~ 'Warp point:' ]]
    then
        fail "should show warp point 'foo'"
    fi

    if [[ ! $(wd show qux) =~ 'No warp point named' ]]
    then
        fail "should not show warp point 'qux'"
    fi
}

test_quiet()
{
    if [[ ! $(wd -q add foo) == "" ]]
    then
        fail "should suppress all output from add"
    fi

    if [[ ! $(wd -q show foo) == "" ]]
    then
        fail "should suppress all output from show"
    fi

    if [[ ! $(wd -q list) == "" ]]
    then
        fail "should suppress all output from ls"
    fi

    if [[ ! $(wd -q rm foo) == "" ]]
    then
        fail "should suppress all output from rm"
    fi
}

test_clean()
{
    dir="$HOME/.wdunittest"

    # create test dir
    mkdir $dir
    cd $dir

    # add warp point
    wd -q add test

    # remove test dir
    cd ..
    rmdir $dir

    if [[ ! $(echo "n" | wd clean) =~ "Cleanup aborted" ]]
    then
        fail "should be able to abort cleanup"
    fi

    if [[ ! $(echo "y" | wd clean) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when answering yes"
    fi

    # recreate test dir
    mkdir $dir
    cd $dir

    # add warp point
    wd -q add test

    if [[ ! $(echo "y" | wd clean) =~ "No warp points to clean, carry on!" ]]
    then
        fail "there should be no invalid warp point"
    fi

	wd -q add! test

    # remove test dir
    cd ..
    rmdir $dir

    if [[ ! $(wd clean!) =~ ".*1 warp point\(s\) removed" ]]
    then
        fail "should remove one warp point when using force"
    fi
}

test_ls()
{
    # set up
    create_test_wp

    # create test files in dir
    touch $WD_TEST_DIR/foo
    touch $WD_TEST_DIR/bar

    # assert correct output
    if [[ ! $(wd ls $WD_TEST_WP) =~ "bar.*foo" ]]
    then
        fail "should list correct files"
    fi

    # clean up
    destroy_test_wp
}

test_path()
{
    # set up
    create_test_wp

    local pwd=$(echo $PWD | sed "s:${HOME}:~:g")

    # assert correct output
    if [[ ! $(wd path $WD_TEST_WP) =~ "${pwd}/${WD_TEST_DIR}" ]]
    then
        fail "should give correct path"
    fi

    # clean up
    destroy_test_wp
}


# Go go gadget
. ./shunit2/shunit2
