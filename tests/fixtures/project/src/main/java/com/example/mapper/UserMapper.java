package com.example.mapper;

import java.util.List;

import com.example.entity.User;

public interface UserMapper {
	User selectUser(Long id);

	List<User> findUsersByUsername(String username);

	int insertUser(User user);

	int updateEmail(Long id, String email);

	int deleteUser(Long id);
}
