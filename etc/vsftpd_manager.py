#!/usr/bin/python3

import argparse, crypt, sys
import os.path
from os.path import exists

parser = argparse.ArgumentParser("Manage VSFTPD virtual users")
parser.add_argument('filename', type=str)
parser.add_argument('action', type=str)
parser.add_argument('user', type=str)
parser.add_argument('--password', '-p', type=str)
parser.add_argument('--force', '-f', action='store_true')
parser.add_argument('--home', type=str, default=None)

USER_UID = os.getenv('VIRTUAL_UID', 1000)
USER_GID = os.getenv('VIRTUAL_GID', 1000)
USER_HOME = os.getenv('VIRTUAL_HOME')


class PwdFile:
    filename = None
    home = None

    def __init__(self, db):
        self.db = db

    @staticmethod
    def create(filename, home=None, halt=False):

        if home and USER_HOME and home not in USER_HOME:
            raise Exception("Home not allowed. Must be inside `%s`" % (USER_HOME, ))
        elif home and not exists(os.path.dirname(home)):
            raise Exception("Home parent directory invalid")

        if not exists(filename):
            if halt:
                raise Exception("File is required")
            else:
                _pwfile = PwdFile({})
                _pwfile.home = home
        else:
            _pwfile = PwdFile({user: password for user, password in
                               map(lambda x: x.split(':'), open(filename, 'r').readlines())})
            _pwfile.filename = filename
            _pwfile.home = home
        return _pwfile

    def add_user(self, user, password, force=False):
        if password is None:
            raise Exception("Password required")
        if not force and user in self.db.keys():
            raise Exception("Username exists, use --force to update anyways")
        self.db[user] = crypt.crypt(password, crypt.METHOD_MD5)

        if self.home and not exists(self.home):
            os.makedirs(self.home, True)
            os.system("chown -R %s:%s %s" % (USER_UID, USER_GID, self.home,))

    def remove_user(self, user, force=False):
        if not self.home and user not in self.db.keys():
            raise Exception("Username invalid")
        self.db.pop(user)

        if self.home and exists(self.home):
            if not force:
                raise Exception("Use --force to remove an existing home")
            else:
                os.system("rm -rf %s" % (self.home,))

    def save(self, filename=None):
        if self.filename is not None and filename is None:
            filename = self.filename

        if filename is None:
            raise Exception("Output file required")

        with open(filename, 'w') as f:
            for key, value in self.db.items():
                f.write('%s:%s\n' % (key, value))
        f.close()


if __name__ == '__main__':

    args = parser.parse_args()
    try:
        if args.action == 'add':
            pwfile = PwdFile.create(args.filename, home=args.home)
            pwfile.add_user(args.user, args.password, args.force)
            pwfile.save(args.filename)
            print("User `%s` added/updated" % (args.user,))
            sys.exit(0)
        elif args.action == 'del':
            pwfile = PwdFile.create(args.filename, args.home, True)
            pwfile.remove_user(args.user)
            pwfile.save(args.filename)
            print("Use `%s` removed" % (args.user,))
            sys.exit(0)
    except Exception as e:
        raise e
        sys.exit(1)

    print("Action not defined/supported")
    sys.exit(0)
