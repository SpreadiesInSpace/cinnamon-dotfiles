from powerline_shell.themes.default import DefaultColor


class Color(DefaultColor):
    """Basic theme which only uses colors in 0-15 range"""
    USERNAME_FG = 15  # White
    USERNAME_BG = 1  # Red
    USERNAME_ROOT_BG = 1

    HOSTNAME_FG = 15  # White
    HOSTNAME_BG = 9  # Red

    HOME_SPECIAL_DISPLAY = False
    PATH_BG = 7  # Light grey
    PATH_FG = 15  # Dark red
    CWD_FG = 15  # White
    SEPARATOR_FG = 15

    READONLY_BG = 1
    READONLY_FG = 15

    REPO_CLEAN_BG = 2  # Green
    REPO_CLEAN_FG = 0  # Black
    REPO_DIRTY_BG = 9  # Red
    REPO_DIRTY_FG = 15  # White

    JOBS_FG = 14
    JOBS_BG = 8  # Dark grey

    CMD_PASSED_BG = 15  # White
    CMD_PASSED_FG = 8  # Dark red
    CMD_FAILED_BG = 1  # Black
    CMD_FAILED_FG = 15  # Light red

    SVN_CHANGES_BG = REPO_DIRTY_BG
    SVN_CHANGES_FG = REPO_DIRTY_FG

    VIRTUAL_ENV_BG = 2  # Green
    VIRTUAL_ENV_FG = 0  # Black

    AWS_PROFILE_FG = 14
    AWS_PROFILE_BG = 8  # Dark grey

    TIME_FG = 9  # Red
    TIME_BG = 7

